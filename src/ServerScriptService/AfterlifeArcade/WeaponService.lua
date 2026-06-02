local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("AfterlifeArcade"):WaitForChild("Config"))

local WeaponService = {}

local lastShotByPlayer = {}
local playerState = {}
local activeFates = {}
local remotes
local enemyService

local function defaultState()
	return {
		weaponId = "Pistol",
		weaponExpiresAt = 0,
		powerups = {},
	}
end

local function getState(player)
	if not playerState[player] then
		playerState[player] = defaultState()
	end
	return playerState[player]
end

local function copyFates(fates)
	local copy = {}
	for fateId, count in pairs(fates or {}) do
		if count > 0 then
			copy[fateId] = count
		end
	end
	return copy
end

local function fateCount(fateId)
	return activeFates[fateId] or 0
end

local function fateEffect(fateId, effectName, defaultValue)
	local fate = Config.Fates and Config.Fates.Pool and Config.Fates.Pool[fateId]
	local effects = fate and fate.Effects
	local value = effects and effects[effectName]
	if value == nil then
		return defaultValue
	end
	return value
end

local function fateDamageMultiplier()
	local bonus = 0
	bonus += fateCount("HeavyHands") * fateEffect("HeavyHands", "DamageMultiplierAdd", 0)
	bonus += fateCount("GlassFlame") * fateEffect("GlassFlame", "DamageMultiplierAdd", 0)
	return 1 + bonus
end

local function fatePierceBonus()
	return fateCount("PiercingRite") * fateEffect("PiercingRite", "PierceBonus", 0)
end

local function weaponConfig(player)
	local state = getState(player)
	if state.weaponId ~= "Pistol" and state.weaponExpiresAt > 0 and os.clock() >= state.weaponExpiresAt then
		state.weaponId = "Pistol"
		state.weaponExpiresAt = 0
	end

	return Config.Weapons[state.weaponId] or Config.Weapons.Pistol, state.weaponId
end

local function activeMultiplier(player, name, defaultValue)
	local state = getState(player)
	local now = os.clock()
	local value = defaultValue

	for powerupId, expiresAt in pairs(state.powerups) do
		if expiresAt <= now then
			state.powerups[powerupId] = nil
		else
			local config = Config.Powerups[powerupId]
			if config and config[name] then
				value *= config[name]
			end
		end
	end

	return value
end

local function activePowerupPayload(player)
	local state = getState(player)
	local now = os.clock()
	local payload = {}

	for powerupId, expiresAt in pairs(state.powerups) do
		if expiresAt > now then
			table.insert(payload, {
				id = powerupId,
				name = Config.Powerups[powerupId].DisplayName,
				remaining = math.max(0, math.floor(expiresAt - now + 0.5)),
			})
		end
	end

	return payload
end

-- WalkSpeed zentral aus den aktiven Buffs ableiten, statt per task.delay
-- zurueckzusetzen. So bricht ein zweiter SpeedBoost den ersten nicht ab.
local function refreshModifiers(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local state = getState(player)
	local now = os.clock()
	local speed = Config.Player.WalkSpeed
	local penalty = character:GetAttribute("AfterlifeWalkSpeedPenalty") or 0
	local speedBoost = state.powerups.SpeedBoost
	if speedBoost and speedBoost > now then
		speed += Config.Powerups.SpeedBoost.WalkSpeedBonus
	end
	speed = math.max(8, speed - penalty)

	if humanoid.WalkSpeed ~= speed then
		humanoid.WalkSpeed = speed
	end
end

local function sendLoadout(player)
	if not remotes or not remotes:FindFirstChild("UpdateLoadout") then
		return
	end

	local weapon, weaponId = weaponConfig(player)
	local state = getState(player)
	local remaining = 0
	if state.weaponExpiresAt > 0 then
		remaining = math.max(0, math.floor(state.weaponExpiresAt - os.clock() + 0.5))
	end

	remotes.UpdateLoadout:FireClient(player, {
		weaponId = weaponId,
		weaponName = weapon.DisplayName,
		weaponRemaining = remaining,
		weaponColor = weapon.Color,
		powerups = activePowerupPayload(player),
	})
end

local function ensureShieldVisual(character)
	local visual = character:FindFirstChild("AfterlifeShieldVisual")
	if visual then
		return visual
	end

	visual = Instance.new("Highlight")
	visual.Name = "AfterlifeShieldVisual"
	visual.FillColor = Config.Powerups.Shield.Color
	visual.OutlineColor = Config.Powerups.Shield.Color
	visual.FillTransparency = 0.72
	visual.OutlineTransparency = 0.08
	visual.DepthMode = Enum.HighlightDepthMode.Occluded
	visual.Parent = character
	return visual
end

local function findEnemyFromHit(instance, enemiesFolder)
	local current = instance
	while current and current ~= Workspace do
		if current.Parent == enemiesFolder and current:GetAttribute("IsAfterlifeEnemy") then
			return current
		end
		current = current.Parent
	end
	return nil
end

local function createTracer(origin, hitPosition, weapon)
	local distance = (hitPosition - origin).Magnitude
	if distance <= 0.1 then
		return
	end

	local width = weapon.TracerWidth or Config.Weapon.TracerWidth
	local tracer = Instance.new("Part")
	tracer.Name = "Tracer"
	tracer.Anchored = true
	tracer.CanCollide = false
	tracer.CanQuery = false
	tracer.Material = Enum.Material.Neon
	tracer.Color = weapon.Color
	tracer.Size = Vector3.new(width, width, distance)
	tracer.CFrame = CFrame.lookAt(origin, hitPosition) * CFrame.new(0, 0, -distance / 2)
	tracer.Parent = Workspace
	Debris:AddItem(tracer, weapon.TracerLifetime or Config.Weapon.TracerLifetime)
end

local function directionWithSpread(direction, spreadDegrees)
	local spread = math.rad((math.random() * 2 - 1) * spreadDegrees)
	return CFrame.Angles(0, spread, 0):VectorToWorldSpace(direction).Unit
end

-- Ein Schuss. Bei weapon.Pierce > 1 durchschlaegt der Strahl mehrere Gegner,
-- bis er eine Wand/Deckung trifft oder das Pierce-Limit erreicht ist.
local function firePellet(player, character, origin, direction, weapon, damage)
	local folder = enemyService.GetFolder()
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local filter = { character }
	rayParams.FilterDescendantsInstances = filter

	local pierce = (weapon.Pierce or 1) + fatePierceBonus()
	local remaining = weapon.Range
	local from = origin
	local endPoint = origin + direction * weapon.Range

	while remaining > 0 and pierce > 0 do
		local result = Workspace:Raycast(from, direction * remaining, rayParams)
		if not result then
			endPoint = from + direction * remaining
			break
		end

		local enemy = findEnemyFromHit(result.Instance, folder)
		if enemy then
			enemyService.Damage(enemy, damage, player)
			pierce -= 1
			endPoint = result.Position
			if pierce <= 0 then
				break
			end
			table.insert(filter, enemy)
			rayParams.FilterDescendantsInstances = filter
			local traveled = (result.Position - from).Magnitude + 0.2
			remaining -= traveled
			from = result.Position + direction * 0.2
		else
			endPoint = result.Position
			break
		end
	end

	createTracer(origin, endPoint, weapon)
end

local function fireVolley(player, character, origin, baseDirection, weapon, damage)
	for _ = 1, weapon.Pellets do
		firePellet(player, character, origin, directionWithSpread(baseDirection, weapon.SpreadDegrees), weapon, damage)
	end
end

local function fireWeapon(player, targetPosition)
	if typeof(targetPosition) ~= "Vector3" then
		return
	end

	local weapon = weaponConfig(player)
	local fireRate = weapon.FireRate * activeMultiplier(player, "FireRateMultiplier", 1)
	local now = os.clock()
	local lastShot = lastShotByPlayer[player] or 0
	if now - lastShot < fireRate then
		return
	end
	lastShotByPlayer[player] = now

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return
	end

	local origin = root.Position + Vector3.new(0, 2, 0)
	local flatTarget = Vector3.new(targetPosition.X, origin.Y, targetPosition.Z)
	local delta = flatTarget - origin
	if delta.Magnitude < 1 then
		return
	end

	local baseDirection = delta.Unit
	local damage = weapon.Damage * activeMultiplier(player, "DamageMultiplier", 1) * fateDamageMultiplier()

	fireVolley(player, character, origin, baseDirection, weapon, damage)

	local burst = weapon.BurstCount or 1
	if burst > 1 then
		local delayStep = weapon.BurstDelay or 0.06
		for shot = 1, burst - 1 do
			task.delay(shot * delayStep, function()
				local char = player.Character
				local r = char and char:FindFirstChild("HumanoidRootPart")
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if not r or not hum or hum.Health <= 0 then
					return
				end
				if weaponConfig(player) ~= weapon then
					return
				end
				local o = r.Position + Vector3.new(0, 2, 0)
				local ft = Vector3.new(targetPosition.X, o.Y, targetPosition.Z)
				local d = ft - o
				if d.Magnitude < 1 then
					return
				end
				fireVolley(player, char, o, d.Unit, weapon, damage)
			end)
		end
	end

	sendLoadout(player)
end

function WeaponService.EquipWeapon(player, weaponId)
	local weapon = Config.Weapons[weaponId]
	if not weapon then
		return false
	end

	local state = getState(player)
	state.weaponId = weaponId
	state.weaponExpiresAt = weapon.DropSeconds > 0 and (os.clock() + weapon.DropSeconds) or 0
	sendLoadout(player)
	return true
end

function WeaponService.ApplyPowerup(player, powerupId)
	local powerup = Config.Powerups[powerupId]
	if not powerup then
		return false
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false
	end

	-- Sofort-Effekte
	if powerup.Heal then
		humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + powerup.Heal)
	end
	if powerup.NukeDamage then
		enemyService.NukeDamage(powerup.NukeDamage, player)
	end
	if powerup.FreezeDuration then
		enemyService.FreezeAll(powerup.FreezeDuration)
	end
	if powerup.ShieldHealth then
		character:SetAttribute("AfterlifeShieldHealth", powerup.ShieldHealth)
		ensureShieldVisual(character)
		task.delay(powerup.Duration, function()
			if character.Parent then
				character:SetAttribute("AfterlifeShieldHealth", 0)
				local visual = character:FindFirstChild("AfterlifeShieldVisual")
				if visual then
					visual:Destroy()
				end
			end
		end)
	end

	-- Dauer-Buffs registrieren (refresh statt kaputtem Stapeln)
	if powerup.Duration and powerup.Duration > 0 then
		local state = getState(player)
		state.powerups[powerupId] = os.clock() + powerup.Duration
	end

	refreshModifiers(player)
	sendLoadout(player)
	return true
end

function WeaponService.IsPowerupActive(player, powerupId)
	local state = playerState[player]
	if not state then
		return false
	end
	local expiresAt = state.powerups[powerupId]
	return expiresAt ~= nil and expiresAt > os.clock()
end

function WeaponService.ApplyRunFates(fates)
	activeFates = copyFates(fates)
	for _, player in ipairs(Players:GetPlayers()) do
		refreshModifiers(player)
		sendLoadout(player)
	end
end

function WeaponService.ResetPlayer(player)
	playerState[player] = defaultState()
	lastShotByPlayer[player] = nil
	refreshModifiers(player)
	sendLoadout(player)
end

function WeaponService.Init(remoteFolder, enemies)
	remotes = remoteFolder
	enemyService = enemies

	remotes.FireWeapon.OnServerEvent:Connect(fireWeapon)

	Players.PlayerAdded:Connect(function(player)
		getState(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.2)
			refreshModifiers(player)
			sendLoadout(player)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		playerState[player] = nil
		lastShotByPlayer[player] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		getState(player)
		sendLoadout(player)
	end

	task.spawn(function()
		while true do
			for _, player in ipairs(Players:GetPlayers()) do
				refreshModifiers(player)
				sendLoadout(player)
			end
			task.wait(0.5)
		end
	end)
end

return WeaponService
