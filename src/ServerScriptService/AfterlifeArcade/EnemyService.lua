local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("AfterlifeArcade"):WaitForChild("Config"))

local EnemyService = {}

local enemiesFolder
local activeEnemies = {}
local enemyDiedCallback
local freezeUntil = 0

local FROZEN_COLOR = Color3.fromRGB(120, 210, 255)
local HIT_FLASH_COLOR = Color3.fromRGB(255, 245, 245)
local ARM_WARN_COLOR = Color3.fromRGB(255, 92, 32)
local CHARGE_COLOR = Color3.fromRGB(210, 255, 220)
local UP_OFFSET = Vector3.new(0, 2, 0)

local function damageHumanoid(humanoid, amount)
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local character = humanoid.Parent
	local invulnerableUntil = character and (character:GetAttribute("AfterlifeInvulnerableUntil") or 0) or 0
	if os.clock() < invulnerableUntil then
		return
	end

	local shield = character and (character:GetAttribute("AfterlifeShieldHealth") or 0) or 0
	if shield > 0 then
		local absorbed = math.min(shield, amount)
		shield -= absorbed
		amount -= absorbed
		character:SetAttribute("AfterlifeShieldHealth", shield)

		local visual = character:FindFirstChild("AfterlifeShieldVisual")
		if visual then
			visual.FillTransparency = shield > 0 and 0.72 or 1
			visual.OutlineTransparency = shield > 0 and 0.08 or 1
		end
	end

	if amount > 0 then
		humanoid:TakeDamage(amount)
	end
end

local function getEnemiesFolder()
	if enemiesFolder and enemiesFolder.Parent then
		return enemiesFolder
	end

	enemiesFolder = Workspace:FindFirstChild("AfterlifeEnemies")
	if not enemiesFolder then
		enemiesFolder = Instance.new("Folder")
		enemiesFolder.Name = "AfterlifeEnemies"
		enemiesFolder.Parent = Workspace
	end

	return enemiesFolder
end

local function getLivingRoot(character)
	if not character then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if humanoid and root and humanoid.Health > 0 then
		return root, humanoid
	end

	return nil
end

local function nearestPlayer(position)
	local bestRoot = nil
	local bestHumanoid = nil
	local bestDistance = math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		local root, humanoid = getLivingRoot(player.Character)
		if root then
			local distance = (root.Position - position).Magnitude
			if distance < bestDistance then
				bestDistance = distance
				bestRoot = root
				bestHumanoid = humanoid
			end
		end
	end

	return bestRoot, bestHumanoid, bestDistance
end

local function enemyStats(enemyTypeId, wave)
	local typeConfig = Config.EnemyTypes[enemyTypeId] or Config.EnemyTypes.Runner
	return {
		typeId = enemyTypeId,
		displayName = typeConfig.DisplayName or enemyTypeId,
		health = typeConfig.Health + (wave - 1) * (typeConfig.HealthPerWave or 0),
		speed = typeConfig.Speed + (wave - 1) * (typeConfig.SpeedPerWave or 0),
		damage = typeConfig.Damage,
		attackRange = typeConfig.AttackRange,
		attackCooldown = typeConfig.AttackCooldown,
		attackMode = typeConfig.AttackMode or "Melee",
		preferredRange = typeConfig.PreferredRange or typeConfig.AttackRange,
		blastRadius = typeConfig.BlastRadius or 0,
		warnTime = typeConfig.WarnTime or 0.7,
		chargeTime = typeConfig.ChargeTime or 0.45,
		score = typeConfig.Score or Config.Rewards.ScorePerEnemy,
		dropChance = typeConfig.DropChance or 0,
		color = typeConfig.Color or Color3.fromRGB(190, 57, 66),
		size = typeConfig.Size or Vector3.new(3.8, 5, 3.8),
		isBoss = typeConfig.Boss == true,
	}
end

local function createBossBar(part, displayName)
	local gui = Instance.new("BillboardGui")
	gui.Name = "BossBar"
	gui.AlwaysOnTop = true
	gui.Size = UDim2.fromOffset(190, 38)
	gui.StudsOffset = Vector3.new(0, part.Size.Y * 0.5 + 4.5, 0)
	gui.Parent = part

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, 18)
	label.Font = Enum.Font.GothamBold
	label.Text = "⚠ " .. string.upper(displayName)
	label.TextColor3 = Color3.fromRGB(255, 196, 120)
	label.TextStrokeTransparency = 0.3
	label.TextSize = 15
	label.Parent = gui

	local back = Instance.new("Frame")
	back.Name = "Back"
	back.AnchorPoint = Vector2.new(0.5, 1)
	back.Position = UDim2.new(0.5, 0, 1, 0)
	back.Size = UDim2.new(1, -8, 0, 12)
	back.BackgroundColor3 = Color3.fromRGB(30, 16, 36)
	back.BorderSizePixel = 0
	back.Parent = gui

	local backCorner = Instance.new("UICorner")
	backCorner.CornerRadius = UDim.new(0, 4)
	backCorner.Parent = back

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(214, 96, 230)
	fill.BorderSizePixel = 0
	fill.Parent = back

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = fill

	return fill
end

local function createEnemyModel(position, wave, enemyTypeId)
	local stats = enemyStats(enemyTypeId, wave)
	local model = Instance.new("Model")
	model.Name = stats.displayName .. "_W" .. tostring(wave)
	model:SetAttribute("IsAfterlifeEnemy", true)
	model:SetAttribute("Wave", wave)
	model:SetAttribute("EnemyType", enemyTypeId)
	model:SetAttribute("Score", stats.score)
	model:SetAttribute("DropChance", stats.dropChance)
	model:SetAttribute("IsBoss", stats.isBoss)

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Anchored = true
	body.CanCollide = false
	body.Size = stats.size
	body.CFrame = CFrame.new(position + Vector3.new(0, stats.size.Y / 2, 0))
	body.Material = Enum.Material.Neon
	body.Color = stats.color
	body.TopSurface = Enum.SurfaceType.Smooth
	body.BottomSurface = Enum.SurfaceType.Smooth
	body.Parent = model

	local baseRange = 10 + body.Size.Y
	local core = Instance.new("PointLight")
	core.Name = "CoreGlow"
	core.Range = baseRange
	core.Brightness = 1.25
	core.Color = stats.color
	core.Parent = body

	local bossFill
	if stats.isBoss then
		bossFill = createBossBar(body, stats.displayName)
	end

	model:SetAttribute("Health", stats.health)
	model:SetAttribute("MaxHealth", stats.health)
	model.PrimaryPart = body
	model.Parent = getEnemiesFolder()

	return model, stats, core, baseRange, bossFill
end

local function createPulse(position, radius, color)
	local pulse = Instance.new("Part")
	pulse.Name = "EnemyPulse"
	pulse.Anchored = true
	pulse.CanCollide = false
	pulse.CanQuery = false
	pulse.Shape = Enum.PartType.Ball
	pulse.Material = Enum.Material.Neon
	pulse.Color = color
	pulse.Transparency = 0.35
	pulse.Size = Vector3.new(1, 1, 1)
	pulse.Position = position
	pulse.Parent = Workspace

	local tween = TweenService:Create(
		pulse,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = Vector3.new(radius * 2, radius * 2, radius * 2), Transparency = 1}
	)
	tween:Play()
	Debris:AddItem(pulse, 0.3)
end

local function createProjectileVisual(origin, target, color)
	local distance = (target - origin).Magnitude
	if distance < 1 then
		return
	end

	local bolt = Instance.new("Part")
	bolt.Name = "SpitterBolt"
	bolt.Anchored = true
	bolt.CanCollide = false
	bolt.CanQuery = false
	bolt.Material = Enum.Material.Neon
	bolt.Color = color
	bolt.Size = Vector3.new(0.32, 0.32, distance)
	bolt.CFrame = CFrame.lookAt(origin, target) * CFrame.new(0, 0, -distance / 2)
	bolt.Parent = Workspace
	Debris:AddItem(bolt, 0.16)
end

local function createChargeVisual(part, duration, color)
	local orb = Instance.new("Part")
	orb.Name = "SpitterCharge"
	orb.Anchored = true
	orb.CanCollide = false
	orb.CanQuery = false
	orb.Shape = Enum.PartType.Ball
	orb.Material = Enum.Material.Neon
	orb.Color = color
	orb.Transparency = 0.2
	orb.Size = Vector3.new(0.6, 0.6, 0.6)
	orb.CFrame = part.CFrame * CFrame.new(0, 0, -part.Size.Z / 2 - 0.6)
	orb.Parent = Workspace

	local tween = TweenService:Create(
		orb,
		TweenInfo.new(math.max(duration, 0.05), Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = Vector3.new(2.6, 2.6, 2.6)}
	)
	tween:Play()
	Debris:AddItem(orb, duration + 0.05)
end

local function damagePlayersInRadius(position, radius, damage)
	for _, player in ipairs(Players:GetPlayers()) do
		local root, humanoid = getLivingRoot(player.Character)
		if root and (root.Position - position).Magnitude <= radius then
			damageHumanoid(humanoid, damage)
		end
	end
end

-- Setzt Farbe/Licht je nach Zustand. "normal" nur einmalig beim Wechsel,
-- damit der Treffer-Flash nicht jeden Frame ueberschrieben wird.
local function applyVisual(model, state, mode, now)
	local part = model.PrimaryPart
	if not part then
		return
	end

	if mode == "normal" then
		if state.visualMode ~= "normal" then
			part.Color = state.baseColor
			if state.light then
				state.light.Color = state.baseColor
				state.light.Brightness = 1.25
				state.light.Range = state.baseRange
			end
			state.visualMode = "normal"
			state._color = state.baseColor
		end
		return
	end

	local color = state.baseColor
	local brightness = 1.25
	local range = state.baseRange

	if mode == "frozen" then
		color = FROZEN_COLOR
		brightness = 0.9
	elseif mode == "arming" then
		local on = (math.floor(now * 12) % 2) == 0
		color = on and ARM_WARN_COLOR or state.baseColor
		brightness = on and 3.0 or 1.4
		range = state.baseRange * 1.4
	elseif mode == "charging" then
		color = CHARGE_COLOR
		brightness = 2.2
		range = state.baseRange * 1.25
	end

	if state._color ~= color then
		part.Color = color
		state._color = color
	end
	if state.light then
		state.light.Color = color
		state.light.Brightness = brightness
		state.light.Range = range
	end
	state.visualMode = mode
end

local function flashHit(model, state)
	local part = model.PrimaryPart
	if not part then
		return
	end

	state.flashGen += 1
	local gen = state.flashGen
	part.Color = HIT_FLASH_COLOR
	state._color = HIT_FLASH_COLOR

	task.delay(0.08, function()
		if part.Parent and state.flashGen == gen and state.visualMode == "normal" and not state.frozen then
			part.Color = state.baseColor
			state._color = state.baseColor
		end
	end)
end

local function destroyEnemy(model, killer)
	local state = activeEnemies[model]
	if not state then
		return
	end

	local position = model.PrimaryPart and model.PrimaryPart.Position or Vector3.zero
	activeEnemies[model] = nil
	model:Destroy()

	if enemyDiedCallback then
		enemyDiedCallback(killer, state.typeId, position, state.wave, state.score, state.dropChance)
	end
end

local function explodeEnemy(model, state)
	local part = model.PrimaryPart
	if not part then
		destroyEnemy(model, nil)
		return
	end

	createPulse(part.Position, state.blastRadius, ARM_WARN_COLOR)
	damagePlayersInRadius(part.Position, state.blastRadius, state.damage)
	destroyEnemy(model, nil)
end

local function moveAndFace(part, current, moveDir, faceDir, speed, dt)
	local nextPosition = current + moveDir * speed * dt
	part.CFrame = CFrame.lookAt(nextPosition, nextPosition + faceDir)
end

local function faceTarget(part, current, faceDir)
	part.CFrame = CFrame.lookAt(current, current + faceDir)
end

local function separationDirection(model, current)
	local config = Config.EnemyMovement
	if not config then
		return Vector3.zero
	end

	local radius = config.SeparationRadius or 0
	if radius <= 0 then
		return Vector3.zero
	end

	local push = Vector3.zero
	local neighbors = 0
	for other, otherState in pairs(activeEnemies) do
		if other ~= model and other.Parent and other.PrimaryPart and not otherState.frozen then
			local offset = current - other.PrimaryPart.Position
			offset = Vector3.new(offset.X, 0, offset.Z)
			local distance = offset.Magnitude
			if distance > 0.05 and distance < radius then
				push += offset.Unit * ((radius - distance) / radius)
				neighbors += 1
				if neighbors >= (config.MaxSeparationNeighbors or 6) then
					break
				end
			end
		end
	end

	if push.Magnitude <= 0.05 then
		return Vector3.zero
	end
	return push.Unit * (config.SeparationStrength or 0.6)
end

local function blendMovement(model, current, primaryDir)
	local separation = separationDirection(model, current)
	if separation.Magnitude <= 0 then
		return primaryDir
	end

	local blended = primaryDir + separation
	if blended.Magnitude <= 0.05 then
		return primaryDir
	end
	return blended.Unit
end

local function updateEnemy(model, state, dt)
	local part = model.PrimaryPart
	if not model.Parent or not part then
		activeEnemies[model] = nil
		return
	end

	local now = os.clock()
	state.frozen = now < freezeUntil

	if state.frozen then
		-- Timer pausieren, damit Warn-/Ladephasen nicht waehrend des Freeze ablaufen.
		if state.arming then
			state.armUntil += dt
		end
		if state.charging then
			state.chargeUntil += dt
		end
		applyVisual(model, state, "frozen", now)
		return
	end

	local targetRoot, targetHumanoid, distance = nearestPlayer(part.Position)
	if not targetRoot then
		applyVisual(model, state, "normal", now)
		return
	end

	local current = part.Position
	local flat = Vector3.new(targetRoot.Position.X - current.X, 0, targetRoot.Position.Z - current.Z)
	local dir = flat.Magnitude > 0.05 and flat.Unit or Vector3.new(0, 0, 1)

	if state.attackMode == "Explode" then
		if state.arming then
			applyVisual(model, state, "arming", now)
			if now >= state.armUntil then
				explodeEnemy(model, state)
			end
			return
		end

		if distance <= state.attackRange then
			state.arming = true
			state.armUntil = now + state.warnTime
			applyVisual(model, state, "arming", now)
		else
			moveAndFace(part, current, blendMovement(model, current, dir), dir, state.speed, dt)
			applyVisual(model, state, "normal", now)
		end
		return
	end

	if state.attackMode == "Ranged" then
		if state.charging then
			applyVisual(model, state, "charging", now)
			if now >= state.chargeUntil then
				state.charging = false
				state.lastAttack = now
				if distance <= state.attackRange * 1.15 then
					createProjectileVisual(part.Position, targetRoot.Position + UP_OFFSET, state.color)
					damageHumanoid(targetHumanoid, state.damage)
				end
				applyVisual(model, state, "normal", now)
			end
			return
		end

		if distance < state.preferredRange * 0.8 then
			moveAndFace(part, current, blendMovement(model, current, -dir), dir, state.speed, dt)
		elseif distance > state.attackRange then
			moveAndFace(part, current, blendMovement(model, current, dir), dir, state.speed, dt)
		else
			faceTarget(part, current, dir)
		end

		if distance <= state.attackRange and now - state.lastAttack >= state.attackCooldown then
			state.charging = true
			state.chargeUntil = now + state.chargeTime
			createChargeVisual(part, state.chargeTime, CHARGE_COLOR)
			applyVisual(model, state, "charging", now)
		else
			applyVisual(model, state, "normal", now)
		end
		return
	end

	-- Melee: Runner (Schwarm), Bruiser (Raumkontrolle), Tank (Boss)
	if distance > state.attackRange then
		moveAndFace(part, current, blendMovement(model, current, dir), dir, state.speed, dt)
	else
		faceTarget(part, current, dir)
	end

	if distance <= state.attackRange and now - state.lastAttack >= state.attackCooldown then
		state.lastAttack = now
		damageHumanoid(targetHumanoid, state.damage)
	end
	applyVisual(model, state, "normal", now)
end

function EnemyService.Init()
	getEnemiesFolder()

	RunService.Heartbeat:Connect(function(dt)
		for model, state in pairs(activeEnemies) do
			updateEnemy(model, state, dt)
		end
	end)
end

function EnemyService.SetEnemyDiedCallback(callback)
	enemyDiedCallback = callback
end

function EnemyService.Spawn(spawnPart, wave, enemyTypeId)
	local typeId = enemyTypeId or "Runner"
	local enemy, stats, light, baseRange, bossFill = createEnemyModel(spawnPart.Position, wave, typeId)
	activeEnemies[enemy] = {
		typeId = typeId,
		wave = wave,
		speed = stats.speed,
		damage = stats.damage,
		attackMode = stats.attackMode,
		attackRange = stats.attackRange,
		preferredRange = stats.preferredRange,
		attackCooldown = stats.attackCooldown,
		blastRadius = stats.blastRadius,
		warnTime = stats.warnTime,
		chargeTime = stats.chargeTime,
		score = stats.score,
		dropChance = stats.dropChance,
		color = stats.color,
		baseColor = stats.color,
		light = light,
		baseRange = baseRange,
		isBoss = stats.isBoss,
		bossFill = bossFill,
		maxHealth = stats.health,
		lastAttack = 0,
		arming = false,
		armUntil = 0,
		charging = false,
		chargeUntil = 0,
		frozen = false,
		flashGen = 0,
		visualMode = "normal",
		_color = stats.color,
	}
	return enemy
end

function EnemyService.Damage(enemyModel, amount, player)
	if not enemyModel or not enemyModel.Parent or not activeEnemies[enemyModel] then
		return false
	end

	local state = activeEnemies[enemyModel]
	local health = enemyModel:GetAttribute("Health") or 0
	health -= amount
	enemyModel:SetAttribute("Health", health)
	flashHit(enemyModel, state)

	if state.bossFill and state.maxHealth > 0 then
		state.bossFill.Size = UDim2.fromScale(math.clamp(health / state.maxHealth, 0, 1), 1)
	end

	if health <= 0 then
		destroyEnemy(enemyModel, player)
		return true
	end

	return false
end

function EnemyService.NukeDamage(amount, player)
	local destroyed = 0
	local targets = {}
	for model in pairs(activeEnemies) do
		if model.Parent then
			table.insert(targets, model)
		end
	end

	for _, model in ipairs(targets) do
		if EnemyService.Damage(model, amount, player) then
			destroyed += 1
		end
	end
	return destroyed
end

function EnemyService.RadialDamage(position, radius, amount, player, color)
	if typeof(position) ~= "Vector3" or radius <= 0 or amount <= 0 then
		return 0
	end

	createPulse(position, radius, color or Color3.fromRGB(112, 206, 255))

	local destroyed = 0
	local targets = {}
	for model in pairs(activeEnemies) do
		if model.Parent and model.PrimaryPart then
			local distance = (model.PrimaryPart.Position - position).Magnitude
			if distance <= radius then
				table.insert(targets, model)
			end
		end
	end

	for _, model in ipairs(targets) do
		if EnemyService.Damage(model, amount, player) then
			destroyed += 1
		end
	end

	return destroyed
end

function EnemyService.FreezeAll(duration)
	freezeUntil = math.max(freezeUntil, os.clock() + (duration or 0))
end

function EnemyService.ClearAll()
	for model in pairs(activeEnemies) do
		if model.Parent then
			model:Destroy()
		end
	end
	activeEnemies = {}
	freezeUntil = 0
end

function EnemyService.Count()
	local count = 0
	for model in pairs(activeEnemies) do
		if model.Parent then
			count += 1
		end
	end
	return count
end

function EnemyService.GetFolder()
	return getEnemiesFolder()
end

return EnemyService
