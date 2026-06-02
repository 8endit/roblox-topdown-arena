local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("AfterlifeArcade"):WaitForChild("Config"))

local WaveService = {}

local currentStage = 0
local currentRoomId = ""
local currentRoomType = "StartRoom"
local currentRoomName = "Start"
local currentLayoutName = "Depot"
local totalSpawnedThisRoom = 0
local targetCountThisRoom = 0
local spawning = false
local statusText = "Preparing"

local remotes
local enemyService
local playerService
local pickupService
local roomService
local activeFates = {}
local stormBursting = false

local function getSpawnParts()
	local map = Workspace:WaitForChild(Config.Map.Name)
	local folder = map:WaitForChild("EnemySpawns")
	return folder:GetChildren()
end

local function broadcast()
	local payload = {
		wave = currentStage,
		enemies = enemyService and enemyService.Count() or 0,
		targetEnemies = targetCountThisRoom,
		status = statusText,
		map = currentLayoutName,
		stage = currentStage,
		roomId = currentRoomId,
		roomType = currentRoomType,
		roomName = currentRoomName,
	}

	for _, player in ipairs(Players:GetPlayers()) do
		remotes.UpdateHud:FireClient(player, payload)
	end
end

local function announceAll(style, text, color)
	local announce = remotes and remotes:FindFirstChild("Announce")
	if announce then
		announce:FireAllClients({style = style, text = text, color = color})
	end
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

local function tryStormVein(player, position)
	local stacks = fateCount("StormVein")
	if stacks <= 0 or stormBursting then
		return
	end

	local chance = math.clamp(stacks * fateEffect("StormVein", "OnKillAoeChance", 0), 0, 0.65)
	if math.random() >= chance then
		return
	end

	local radius = fateEffect("StormVein", "OnKillAoeRadius", 0)
	local damage = fateEffect("StormVein", "OnKillAoeDamage", 0)
	local color = Config.Fates.Pool.StormVein.Color

	stormBursting = true
	enemyService.RadialDamage(position, radius, damage, player, color)
	stormBursting = false
	announceAll("toast", "Storm Vein", color)
end

local function chooseSpawn(spawns)
	local candidates = {}
	local minDistance = Config.Spawning.MinPlayerDistance or 0

	for _, spawn in ipairs(spawns) do
		local nearest = math.huge
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if humanoid and humanoid.Health > 0 and root then
				nearest = math.min(nearest, (root.Position - spawn.Position).Magnitude)
			end
		end

		if nearest == math.huge then
			nearest = minDistance
		end
		table.insert(candidates, {spawn = spawn, distance = nearest})
	end

	table.sort(candidates, function(a, b)
		return a.distance > b.distance
	end)

	local filtered = {}
	for _, candidate in ipairs(candidates) do
		if candidate.distance >= minDistance then
			table.insert(filtered, candidate.spawn)
		end
	end

	if #filtered > 0 then
		local top = math.min(#filtered, Config.Spawning.PreferFarthestCount or #filtered)
		return filtered[math.random(1, top)]
	end

	local top = math.min(#candidates, Config.Spawning.PreferFarthestCount or #candidates)
	return candidates[math.random(1, top)].spawn
end

local function weightedChoice(entries)
	local totalWeight = 0
	for _, entry in ipairs(entries) do
		totalWeight += entry.weight
	end

	if totalWeight <= 0 then
		return entries[1] and entries[1].id or "Runner"
	end

	local roll = math.random() * totalWeight
	local cursor = 0
	for _, entry in ipairs(entries) do
		cursor += entry.weight
		if roll <= cursor then
			return entry.id
		end
	end

	return entries[#entries].id
end

local function roomBudget(stage, roomConfig)
	local budget = Config.Waves.BaseBudget + (stage - 1) * Config.Waves.BudgetPerWave
	return math.max(0, math.floor(budget * (roomConfig.BudgetMult or 1)))
end

local function enemyWeightsFor(roomConfig)
	local weights = roomConfig.EnemyWeights or {}
	if next(weights) then
		return weights
	end
	return {Runner = 8, Bruiser = 4, Spitter = 3, Exploder = 2}
end

local function buildEnemyQueue(stage, roomConfig)
	local queue = {}
	local budget = roomBudget(stage, roomConfig)

	if roomConfig.Boss then
		table.insert(queue, roomConfig.Boss)
		budget -= Config.EnemyTypes[roomConfig.Boss].Cost
	end

	while budget > 0 do
		local choices = {}
		local weights = enemyWeightsFor(roomConfig)
		for id, weight in pairs(weights) do
			local enemyConfig = Config.EnemyTypes[id]
			if enemyConfig and stage >= enemyConfig.MinWave and enemyConfig.Cost <= budget then
				table.insert(choices, {id = id, weight = weight})
			end
		end

		if #choices == 0 then
			break
		end

		local id = weightedChoice(choices)
		table.insert(queue, id)
		budget -= Config.EnemyTypes[id].Cost
	end

	return queue
end

local function runRoom(stage, roomId, room, roomConfig, layoutId)
	currentStage = stage
	currentRoomId = roomId
	currentRoomType = room.type or "CombatRoom"
	currentRoomName = roomConfig.DisplayName or currentRoomType
	currentLayoutName = (Config.MapLayouts[layoutId] and Config.MapLayouts[layoutId].DisplayName) or layoutId

	local queue = buildEnemyQueue(stage, roomConfig)
	totalSpawnedThisRoom = 0
	targetCountThisRoom = #queue
	spawning = true
	statusText = currentRoomName
	playerService.SetWaveForAll(stage)
	broadcast()

	if roomConfig.Boss then
		announceAll("banner", "STAGE " .. tostring(stage) .. " - BOSS", Color3.fromRGB(255, 110, 90))
	else
		announceAll("banner", currentRoomName, Color3.fromRGB(120, 230, 200))
	end

	local spawns = getSpawnParts()
	for _, enemyTypeId in ipairs(queue) do
		if #spawns > 0 then
			enemyService.Spawn(chooseSpawn(spawns), stage, enemyTypeId)
			totalSpawnedThisRoom += 1
			broadcast()
		end
		task.wait(Config.Waves.SpawnInterval)
	end

	spawning = false
	statusText = "Clear the room"
	broadcast()

	while enemyService.Count() > 0 do
		broadcast()
		task.wait(0.75)
	end

	statusText = "Room clear"
	broadcast()
	if roomService then
		roomService.OnRoomCleared(roomId)
	end
end

function WaveService.PlayRoom(stage, roomId, room, roomConfig, layoutId)
	task.spawn(function()
		runRoom(stage, roomId, room, roomConfig, layoutId)
	end)
end

function WaveService.SetRoomService(service)
	roomService = service
end

function WaveService.ApplyRunFates(fates)
	activeFates = copyFates(fates)
end

function WaveService.Init(remoteFolder, enemies, players, maps, pickups)
	remotes = remoteFolder
	enemyService = enemies
	playerService = players
	pickupService = pickups

	enemyService.SetEnemyDiedCallback(function(player, enemyTypeId, position, stage, score, dropChance)
		playerService.AddScore(player, score or Config.Rewards.ScorePerEnemy)
		if pickupService then
			pickupService.TryDropForEnemy(enemyTypeId, position, stage, dropChance)
		end
		if Config.EnemyTypes[enemyTypeId] and Config.EnemyTypes[enemyTypeId].Boss then
			announceAll("banner", "BOSS DOWN", Color3.fromRGB(120, 230, 200))
		end
		tryStormVein(player, position)
		broadcast()
	end)
end

return WaveService
