local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("AfterlifeArcade"):WaitForChild("Config"))

local RunService = {}

local remotes
local roomService
local weaponService
local playerService
local enemyService
local waveService

local state = "WAITING"
local runId = 0
local lives = Config.Run.StartLives
local kills = 0
local startedAt = 0
local handlingDeath = {}

local function runStatePayload()
	return {
		state = state,
		runId = runId,
		lives = lives,
		kills = kills,
	}
end

local function broadcastRunState()
	local remote = remotes and remotes:FindFirstChild("UpdateRunState")
	if remote then
		remote:FireAllClients(runStatePayload())
	end
end

local function announceAll(style, text, color)
	local announce = remotes and remotes:FindFirstChild("Announce")
	if announce then
		announce:FireAllClients({style = style, text = text, color = color})
	end
end

local function totalScore()
	local total = 0
	for _, player in ipairs(Players:GetPlayers()) do
		local leaderstats = player:FindFirstChild("leaderstats")
		local score = leaderstats and leaderstats:FindFirstChild("Score")
		total += score and score.Value or 0
	end
	return total
end

local function currentStage()
	local roomState = roomService and roomService.GetState and roomService.GetState()
	return roomState and roomState.stage or 0
end

local function formatFates()
	local fates = {}
	local roomState = roomService and roomService.GetState and roomService.GetState()
	for _, fate in ipairs((roomState and roomState.fates) or {}) do
		local suffix = fate.count and fate.count > 1 and (" x" .. tostring(fate.count)) or ""
		table.insert(fates, tostring(fate.name) .. suffix)
	end
	return fates
end

local function summaryPayload()
	return {
		stage = currentStage(),
		score = totalScore(),
		kills = kills,
		timeSeconds = startedAt > 0 and math.floor(os.clock() - startedAt) or 0,
		fates = formatFates(),
		summarySeconds = Config.Run.SummarySeconds,
		newBest = false,
	}
end

local function resetPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		if playerService and playerService.ResetPlayer then
			playerService.ResetPlayer(player, true)
		end
		if weaponService and weaponService.ResetPlayer then
			weaponService.ResetPlayer(player)
		end
		player:LoadCharacter()
	end
end

local function bindCharacter(player, character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then
		return
	end

	humanoid.Died:Connect(function()
		RunService.OnPlayerDied(player)
	end)
end

local function setupPlayer(player)
	player.CharacterAdded:Connect(function(character)
		bindCharacter(player, character)
		if state == "ACTIVE" then
			task.defer(function()
				if playerService and playerService.GrantIFrames then
					playerService.GrantIFrames(player, Config.Run.RespawnIFrames)
				end
			end)
		end
	end)

	if player.Character then
		bindCharacter(player, player.Character)
	end
end

function RunService.StartRun()
	runId += 1
	state = "RESETTING"
	lives = Config.Run.StartLives
	kills = 0
	startedAt = os.clock()
	handlingDeath = {}

	if enemyService and enemyService.ClearAll then
		enemyService.ClearAll()
	end
	if waveService and waveService.ResetRun then
		waveService.ResetRun()
	end
	if weaponService and weaponService.ApplyRunFates then
		weaponService.ApplyRunFates({})
	end

	resetPlayers()

	state = "ACTIVE"
	if roomService and roomService.ResetRun then
		roomService.ResetRun()
	end

	broadcastRunState()
	announceAll("banner", "RUN START", Color3.fromRGB(120, 230, 200))
end

function RunService.GameOver()
	if state == "GAMEOVER" then
		return
	end

	state = "GAMEOVER"
	broadcastRunState()

	local payload = summaryPayload()

	if waveService and waveService.ResetRun then
		waveService.ResetRun()
	end
	if enemyService and enemyService.ClearAll then
		enemyService.ClearAll()
	end
	if roomService and roomService.StopRun then
		roomService.StopRun()
	end
	local summaryRemote = remotes and remotes:FindFirstChild("RunSummary")
	if summaryRemote then
		summaryRemote:FireAllClients(payload)
	end
	announceAll("banner", "GAME OVER", Color3.fromRGB(255, 92, 92))

	task.delay(Config.Run.SummarySeconds, function()
		if state == "GAMEOVER" then
			RunService.StartRun()
		end
	end)
end

function RunService.OnPlayerDied(player)
	if state ~= "ACTIVE" or handlingDeath[player] then
		return
	end

	handlingDeath[player] = true
	lives = math.max(0, lives - 1)
	broadcastRunState()

	if lives <= 0 then
		RunService.GameOver()
		task.delay(1, function()
			handlingDeath[player] = nil
		end)
		return
	end

	announceAll("toast", "Life lost - " .. tostring(lives) .. " left", Color3.fromRGB(255, 196, 120))
	task.delay(Config.Run.RespawnDelay, function()
		if state == "ACTIVE" and player.Parent then
			player:LoadCharacter()
		end
		handlingDeath[player] = nil
	end)
end

function RunService.RegisterKill()
	if state == "ACTIVE" then
		kills += 1
		broadcastRunState()
	end
end

function RunService.GetState()
	return runStatePayload()
end

function RunService.Init(remoteFolder, rooms, weapons, players, enemies, waves)
	remotes = remoteFolder
	roomService = rooms
	weaponService = weapons
	playerService = players
	enemyService = enemies
	waveService = waves

	Players.PlayerAdded:Connect(setupPlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	task.spawn(function()
		while #Players:GetPlayers() == 0 do
			broadcastRunState()
			task.wait(1)
		end
		RunService.StartRun()
	end)
end

return RunService
