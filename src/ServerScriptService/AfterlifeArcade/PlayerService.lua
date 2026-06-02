local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("AfterlifeArcade"):WaitForChild("Config"))

local PlayerService = {}
local lastDashByPlayer = {}
local activeFates = {}

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

local function copyFates(fates)
	local copy = {}
	for fateId, count in pairs(fates or {}) do
		if count > 0 then
			copy[fateId] = count
		end
	end
	return copy
end

local function calculateDashCooldown()
	local reduction = fateCount("FleetSoul") * fateEffect("FleetSoul", "DashCooldownReduction", 0)
	local minCooldown = fateEffect("FleetSoul", "MinDashCooldown", Config.Player.DashCooldown)
	return math.max(minCooldown, Config.Player.DashCooldown - reduction)
end

local function calculateWalkSpeedPenalty()
	return fateCount("HeavyHands") * fateEffect("HeavyHands", "WalkSpeedPenalty", 0)
end

local function calculateMaxHealth()
	local penalty = fateCount("GlassFlame") * fateEffect("GlassFlame", "MaxHealthPenalty", 0)
	local minHealth = fateEffect("GlassFlame", "MinMaxHealth", Config.Player.MaxHealth)
	return math.max(minHealth, Config.Player.MaxHealth - penalty)
end

local function applyFatesToCharacter(character)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local maxHealth = calculateMaxHealth()
	local oldMaxHealth = humanoid.MaxHealth
	humanoid.MaxHealth = maxHealth
	if oldMaxHealth <= 0 then
		humanoid.Health = maxHealth
	elseif humanoid.Health > maxHealth then
		humanoid.Health = maxHealth
	end

	character:SetAttribute("AfterlifeDashCooldown", calculateDashCooldown())
	character:SetAttribute("AfterlifeWalkSpeedPenalty", calculateWalkSpeedPenalty())
	character:SetAttribute("AfterlifeMaxHealth", maxHealth)
end

local function applyFatesToAllCharacters()
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			applyFatesToCharacter(player.Character)
		end
	end
end

local function setupLeaderstats(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local score = leaderstats:FindFirstChild("Score")
	if not score then
		score = Instance.new("IntValue")
		score.Name = "Score"
		score.Value = 0
		score.Parent = leaderstats
	end

	local wave = leaderstats:FindFirstChild("Wave")
	if not wave then
		wave = Instance.new("IntValue")
		wave.Name = "Wave"
		wave.Value = 0
		wave.Parent = leaderstats
	end
end

local function configureCharacter(character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not root then
		return
	end

	humanoid.MaxHealth = Config.Player.MaxHealth
	humanoid.Health = Config.Player.MaxHealth
	humanoid.WalkSpeed = Config.Player.WalkSpeed
	humanoid.AutoRotate = false
	character:SetAttribute("AfterlifeShieldHealth", 0)
	character:SetAttribute("AfterlifeInvulnerableUntil", 0)
	character:SetAttribute("AfterlifeDashCooldown", Config.Player.DashCooldown)
	character:SetAttribute("AfterlifeWalkSpeedPenalty", 0)
	character:SetAttribute("AfterlifeMaxHealth", Config.Player.MaxHealth)
	applyFatesToCharacter(character)
	root.CFrame = CFrame.new(Config.Map.PlayerSpawn)
end

local function createDashGhost(root)
	local ghost = Instance.new("Part")
	ghost.Name = "DashGhost"
	ghost.Anchored = true
	ghost.CanCollide = false
	ghost.CanQuery = false
	ghost.Material = Enum.Material.Neon
	ghost.Color = Color3.fromRGB(120, 230, 255)
	ghost.Transparency = 0.55
	ghost.Size = Vector3.new(3, 5, 3)
	ghost.CFrame = root.CFrame
	ghost.Parent = workspace
	game:GetService("Debris"):AddItem(ghost, Config.Player.DashGhostLifetime)
end

local function dashPlayer(player, direction)
	if typeof(direction) ~= "Vector3" then
		return
	end

	local now = os.clock()
	local character = player.Character
	local cooldown = (character and character:GetAttribute("AfterlifeDashCooldown")) or Config.Player.DashCooldown
	if now - (lastDashByPlayer[player] or 0) < cooldown then
		return
	end

	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root then
		return
	end

	local flat = Vector3.new(direction.X, 0, direction.Z)
	if flat.Magnitude < 0.05 then
		return
	end
	flat = flat.Unit

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local exclude = { character }
	local enemies = workspace:FindFirstChild("AfterlifeEnemies")
	local pickups = workspace:FindFirstChild("AfterlifePickups")
	if enemies then
		table.insert(exclude, enemies)
	end
	if pickups then
		table.insert(exclude, pickups)
	end
	rayParams.FilterDescendantsInstances = exclude

	local result = workspace:Raycast(root.Position, flat * Config.Player.DashDistance, rayParams)
	local distance = Config.Player.DashDistance
	if result then
		distance = math.max(0, (result.Position - root.Position).Magnitude - 4)
	end

	lastDashByPlayer[player] = now
	character:SetAttribute("AfterlifeInvulnerableUntil", now + Config.Player.DashIFrames)
	createDashGhost(root)
	root.CFrame = CFrame.lookAt(root.Position + flat * distance, root.Position + flat * distance + flat)
end

function PlayerService.Init(remotes)
	Players.PlayerAdded:Connect(function(player)
		setupLeaderstats(player)
		player.CharacterAdded:Connect(configureCharacter)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		setupLeaderstats(player)
		if player.Character then
			configureCharacter(player.Character)
		end
		player.CharacterAdded:Connect(configureCharacter)
	end

	if remotes and remotes:FindFirstChild("Dash") then
		remotes.Dash.OnServerEvent:Connect(dashPlayer)
	end
end

function PlayerService.AddScore(player, amount)
	if not player then
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local score = leaderstats and leaderstats:FindFirstChild("Score")
	if score then
		score.Value += amount
	end
end

function PlayerService.SetWaveForAll(wave)
	for _, player in ipairs(Players:GetPlayers()) do
		local leaderstats = player:FindFirstChild("leaderstats")
		local waveValue = leaderstats and leaderstats:FindFirstChild("Wave")
		if waveValue then
			waveValue.Value = wave
		end
	end
end

function PlayerService.ApplyRunFates(fates)
	activeFates = copyFates(fates)
	applyFatesToAllCharacters()
end

function PlayerService.TeleportAllToSpawn()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then
			root.CFrame = CFrame.new(Config.Map.PlayerSpawn)
		end
	end
end

return PlayerService
