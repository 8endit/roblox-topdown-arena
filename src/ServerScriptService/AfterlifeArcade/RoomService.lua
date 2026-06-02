local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("AfterlifeArcade"):WaitForChild("Config"))

local RoomService = {}

local remotes
local mapBuilder
local playerService
local pickupService
local waveService
local weaponService

local currentStage = 0
local currentRoomId = nil
local currentRoomType = "StartRoom"
local currentLayoutId = Config.MapRotation[1]
local currentGraph = nil
local clearedRooms = {}
local runFates = {}
local gatesFolder
local teleporter
local fateFolder
local roomRunning = false
local pendingTransition = false
local enterClearedRoom

local DIRECTION_NAMES = {
	N = "NORTH",
	S = "SOUTH",
	E = "EAST",
	W = "WEST",
}

local function announceAll(style, text, color)
	local announce = remotes and remotes:FindFirstChild("Announce")
	if announce then
		announce:FireAllClients({style = style, text = text, color = color})
	end
end

local function activeFatePayload()
	local payload = {}
	for fateId, count in pairs(runFates) do
		local fate = Config.Fates and Config.Fates.Pool and Config.Fates.Pool[fateId]
		if fate and count > 0 then
			table.insert(payload, {
				id = fateId,
				name = fate.DisplayName or fateId,
				count = count,
				color = fate.Color,
			})
		end
	end
	table.sort(payload, function(a, b)
		return a.name < b.name
	end)
	return payload
end

local function applyRunFates()
	if playerService and playerService.ApplyRunFates then
		playerService.ApplyRunFates(runFates)
	end
	if weaponService and weaponService.ApplyRunFates then
		weaponService.ApplyRunFates(runFates)
	end
	if waveService and waveService.ApplyRunFates then
		waveService.ApplyRunFates(runFates)
	end
end

local function getRoom(roomId)
	if not currentGraph then
		return nil
	end
	local nodes = currentGraph.nodes
	return nodes and nodes[roomId]
end

local function roomType(room)
	return room and room.type or "CombatRoom"
end

local function roomNext(room)
	return room and room.next or {}
end

local function isTerminalRoom(room)
	return room and room.terminal == true
end

local function roomConfig(room)
	return room and Config.Rooms[roomType(room)] or Config.Rooms.CombatRoom
end

local function layoutFor(roomId, room)
	local config = roomConfig(room)
	local layouts = config.Layouts or Config.MapRotation
	local seed = currentStage * 17 + string.len(roomId or "")
	local index = ((seed - 1) % #layouts) + 1
	return layouts[index]
end

local function layoutName()
	return (Config.MapLayouts[currentLayoutId] and Config.MapLayouts[currentLayoutId].DisplayName) or currentLayoutId
end

local function destroyGates()
	if gatesFolder then
		gatesFolder:Destroy()
		gatesFolder = nil
	end
end

local function destroyTeleporter()
	if teleporter then
		teleporter:Destroy()
		teleporter = nil
	end
end

local function destroyFateOffer()
	if fateFolder then
		fateFolder:Destroy()
		fateFolder = nil
	end
end

local function clearTransitionObjects()
	destroyGates()
	destroyTeleporter()
	destroyFateOffer()
end

local function broadcast(status)
	local room = getRoom(currentRoomId)
	local config = roomConfig(room)
	local payload = {
		stage = currentStage,
		roomId = currentRoomId or "",
		roomType = currentRoomType,
		roomName = config.DisplayName or currentRoomType,
		status = status,
		map = layoutName(),
		terminal = isTerminalRoom(room),
		fates = activeFatePayload(),
	}

	for _, player in ipairs(Players:GetPlayers()) do
		if remotes and remotes:FindFirstChild("UpdateRun") then
			remotes.UpdateRun:FireClient(player, payload)
		end
	end
end

local function arenaBounds()
	local map = Workspace:FindFirstChild(Config.Map.Name)
	local arena = map and map:FindFirstChild("Arena")
	local floor = arena and arena:FindFirstChild("Floor")
	if floor then
		return floor.Size.X / 2, floor.Size.Z / 2
	end
	return Config.Map.Width / 2, Config.Map.Depth / 2
end

local function gateCFrame(direction)
	local halfX, halfZ = arenaBounds()
	local margin = 8
	if direction == "N" then
		return CFrame.new(0, 3, -halfZ + margin)
	elseif direction == "S" then
		return CFrame.new(0, 3, halfZ - margin)
	elseif direction == "E" then
		return CFrame.new(halfX - margin, 3, 0) * CFrame.Angles(0, math.rad(90), 0)
	elseif direction == "W" then
		return CFrame.new(-halfX + margin, 3, 0) * CFrame.Angles(0, math.rad(90), 0)
	end
	return CFrame.new(0, 3, 0)
end

local function createLabel(part, text, color)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.AlwaysOnTop = true
	gui.Size = UDim2.fromOffset(170, string.find(text, "\n") and 58 or 34)
	gui.StudsOffset = Vector3.new(0, 4.2, 0)
	gui.Parent = part

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.35
	label.TextSize = 15
	label.TextWrapped = true
	label.Parent = gui
end

local function createGate(direction, targetRoomId)
	local target = getRoom(targetRoomId)
	local targetConfig = roomConfig(target)
	local targetType = roomType(target)
	local color = (Config.Gates.ColorsByTargetType and Config.Gates.ColorsByTargetType[targetType])
		or Config.Gates.Color

	local part = Instance.new("Part")
	part.Name = "Gate_" .. direction .. "_" .. targetRoomId
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Size = Vector3.new(2, 9, Config.Gates.Radius * 2)
	part.CFrame = gateCFrame(direction)
	part.Material = Enum.Material.Neon
	part.Color = color
	part.Parent = gatesFolder

	local light = Instance.new("PointLight")
	light.Name = "GateGlow"
	light.Range = 24
	light.Brightness = 1.8
	light.Color = color
	light.Parent = part

	createLabel(part, (DIRECTION_NAMES[direction] or direction) .. " - " .. (targetConfig.DisplayName or targetType), color)

	local consumed = false
	part.Touched:Connect(function(hit)
		if consumed or roomRunning or pendingTransition then
			return
		end

		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then
			return
		end

		consumed = true
		task.defer(function()
			RoomService.LoadRoom(targetRoomId)
		end)
	end)
end

local function openGates()
	destroyGates()
	local room = getRoom(currentRoomId)
	if not room then
		return
	end

	gatesFolder = Instance.new("Folder")
	gatesFolder.Name = "AfterlifeGates"
	gatesFolder.Parent = Workspace

	for targetRoomId, direction in pairs(roomNext(room)) do
		createGate(direction, targetRoomId)
	end
end

local function createStageTeleporter()
	destroyTeleporter()
	local color = Config.StageTeleporter.TeleporterColor

	local part = Instance.new("Part")
	part.Name = "StageTeleporter"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(1, Config.StageTeleporter.TeleporterRadius * 2, Config.StageTeleporter.TeleporterRadius * 2)
	part.CFrame = CFrame.new(0, 1.2, 0) * CFrame.Angles(0, 0, math.rad(90))
	part.Material = Enum.Material.Neon
	part.Color = color
	part.Parent = Workspace

	local light = Instance.new("PointLight")
	light.Name = "StageTeleporterGlow"
	light.Range = 34
	light.Brightness = 2.3
	light.Color = color
	light.Parent = part

	createLabel(part, "NEXT STAGE", color)

	local consumed = false
	part.Touched:Connect(function(hit)
		if consumed or roomRunning or pendingTransition then
			return
		end
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then
			return
		end

		consumed = true
		task.defer(function()
			RoomService.StartNextStage()
		end)
	end)

	teleporter = part
end

local function spawnTreasure(room)
	local config = roomConfig(room)
	if not config.PrePlacedLoot or not pickupService then
		return
	end

	pickupService.SpawnPowerup("Health", Vector3.new(-8, Config.Map.FloorY + 1, 0), "Rare")
	pickupService.SpawnWeapon("SMG", Vector3.new(8, Config.Map.FloorY + 1, 0), "Rare")
end

local function awardRoomScore(room)
	if not playerService or not playerService.AddScoreAll then
		return
	end

	local typeId = roomType(room)
	if typeId ~= "StartRoom" then
		playerService.AddScoreAll(Config.Score.RoomClear or 0)
	end
	if typeId == "TreasureRoom" then
		playerService.AddScoreAll(Config.Score.TreasureDetour or 0)
	end
	if isTerminalRoom(room) then
		playerService.AddScoreAll(Config.Score.StageClear or 0)
	end
end

local function sortedFateIds(pool)
	local ids = {}
	for fateId in pairs(pool or {}) do
		table.insert(ids, fateId)
	end
	table.sort(ids)
	return ids
end

local function availableFateIds()
	local ids = {}
	local pool = Config.Fates and Config.Fates.Pool or {}
	for _, fateId in ipairs(sortedFateIds(pool)) do
		local fate = pool[fateId]
		local owned = runFates[fateId] or 0
		local maxStacks = fate and fate.MaxStacks or math.huge
		if fate and owned < maxStacks and not (fate.Unique and owned > 0) then
			table.insert(ids, fateId)
		end
	end

	for index = #ids, 2, -1 do
		local swap = math.random(1, index)
		ids[index], ids[swap] = ids[swap], ids[index]
	end

	return ids
end

local function pedestalCFrame(index, count)
	local spacing = Config.Fates.PedestalSpacing or 12
	local offset = (index - ((count + 1) / 2)) * spacing
	return CFrame.new(offset, Config.Map.FloorY + 2.2, 0)
end

local function createFateOffer()
	destroyFateOffer()
	local ids = availableFateIds()
	if #ids == 0 then
		clearedRooms[currentRoomId] = true
		enterClearedRoom()
		return
	end

	local count = math.min(Config.Fates.OfferCount or 3, #ids)
	fateFolder = Instance.new("Folder")
	fateFolder.Name = "AfterlifeFateOffer"
	fateFolder.Parent = Workspace

	local chosen = false
	for index = 1, count do
		local fateId = ids[index]
		local fate = Config.Fates.Pool[fateId]
		local color = fate.Color or Config.Fates.PedestalColor

		local part = Instance.new("Part")
		part.Name = "Fate_" .. fateId
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.Size = Vector3.new(5, 2.4, 5)
		part.CFrame = pedestalCFrame(index, count)
		part.Material = Enum.Material.Neon
		part.Color = color
		part.Parent = fateFolder

		local light = Instance.new("PointLight")
		light.Name = "FateGlow"
		light.Range = 22
		light.Brightness = 1.8
		light.Color = color
		light.Parent = part

		createLabel(part, (fate.DisplayName or fateId) .. "\n" .. (fate.Description or ""), color)

		part.Touched:Connect(function(hit)
			if chosen or roomRunning or pendingTransition then
				return
			end
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if not player then
				return
			end

			chosen = true
			runFates[fateId] = (runFates[fateId] or 0) + 1
			applyRunFates()
			announceAll("toast", (fate.DisplayName or fateId) .. " chosen", color)
			destroyFateOffer()
			clearedRooms[currentRoomId] = true
			enterClearedRoom()
		end)
	end
end

local function resolveStageTemplate(stage)
	local templates = Config.Stages.Templates
	if templates[stage] then
		return templates[stage]
	end

	local repeatFrom = Config.Stages.RepeatFromStage or 4
	local repeatTo = Config.Stages.RepeatToStage or 7
	if stage > repeatTo and templates[repeatFrom] and templates[repeatTo] then
		local span = repeatTo - repeatFrom + 1
		local repeatedStage = repeatFrom + ((stage - repeatFrom) % span)
		return templates[repeatedStage]
	end

	return templates[3] or templates[1]
end

enterClearedRoom = function()
	roomRunning = false
	broadcast("Room clear")
	local room = getRoom(currentRoomId)
	if isTerminalRoom(room) then
		announceAll("banner", "STAGE " .. tostring(currentStage) .. " CLEAR", Color3.fromRGB(120, 230, 200))
		createStageTeleporter()
	else
		openGates()
	end
end

function RoomService.LoadRoom(roomId)
	if pendingTransition then
		return
	end

	local room = getRoom(roomId)
	if not room then
		return
	end

	pendingTransition = true
	roomRunning = false
	clearTransitionObjects()
	if pickupService then
		pickupService.ClearAll()
	end

	currentRoomId = roomId
	currentRoomType = roomType(room)
	currentLayoutId = layoutFor(roomId, room)

	mapBuilder.Build(currentLayoutId)
	playerService.TeleportAllToSpawn()
	broadcast("Entering room")

	local config = roomConfig(room)
	announceAll("banner", "STAGE " .. tostring(currentStage) .. " - " .. (config.DisplayName or currentRoomType), Color3.fromRGB(120, 230, 200))

	task.wait(Config.Stages.StartDelay)
	pendingTransition = false

	if clearedRooms[roomId] then
		enterClearedRoom()
		return
	end

	if config.Clear == "instant" then
		clearedRooms[roomId] = true
		spawnTreasure(room)
		awardRoomScore(room)
		enterClearedRoom()
		return
	end

	if config.Clear == "chooseFate" then
		announceAll("banner", "CHOOSE A FATE", Config.Fates.PedestalColor)
		createFateOffer()
		return
	end

	roomRunning = true
	waveService.PlayRoom(currentStage, currentRoomId, room, config, currentLayoutId)
end

function RoomService.StartNextStage()
	if pendingTransition then
		return
	end

	currentStage += 1
	currentGraph = resolveStageTemplate(currentStage)
	clearedRooms = {}
	clearTransitionObjects()
	announceAll("banner", "STAGE " .. tostring(currentStage), Color3.fromRGB(120, 230, 200))
	RoomService.LoadRoom(currentGraph.start or "s")
end

function RoomService.StopRun()
	roomRunning = false
	pendingTransition = false
	currentGraph = nil
	currentRoomId = nil
	currentRoomType = "StartRoom"
	currentStage = 0
	clearedRooms = {}
	clearTransitionObjects()
	if pickupService then
		pickupService.ClearAll()
	end
	broadcast("Run stopped")
end

function RoomService.ResetRun()
	roomRunning = false
	pendingTransition = false
	currentStage = 0
	currentRoomId = nil
	currentRoomType = "StartRoom"
	currentLayoutId = Config.MapRotation[1]
	currentGraph = nil
	clearedRooms = {}
	runFates = {}
	clearTransitionObjects()
	if pickupService then
		pickupService.ClearAll()
	end
	applyRunFates()
	RoomService.StartNextStage()
end

function RoomService.OnRoomCleared(roomId)
	if roomId ~= currentRoomId then
		return
	end

	roomRunning = false
	clearedRooms[roomId] = true
	broadcast("Room clear")

	local room = getRoom(roomId)
	awardRoomScore(room)
	if isTerminalRoom(room) then
		announceAll("banner", "STAGE " .. tostring(currentStage) .. " CLEAR", Color3.fromRGB(120, 230, 200))
		createStageTeleporter()
	else
		openGates()
	end
end

function RoomService.GetState()
	return {
		stage = currentStage,
		roomId = currentRoomId,
		roomType = currentRoomType,
		layoutId = currentLayoutId,
		fates = activeFatePayload(),
	}
end

function RoomService.Init(remoteFolder, maps, players, pickups, waves, weapons, autoStart)
	remotes = remoteFolder
	mapBuilder = maps
	playerService = players
	pickupService = pickups
	waveService = waves
	weaponService = weapons
	applyRunFates()

	if autoStart ~= false then
		task.spawn(function()
			while #Players:GetPlayers() == 0 do
				broadcast("Waiting for players")
				task.wait(1)
			end
			RoomService.StartNextStage()
		end)
	end
end

return RoomService
