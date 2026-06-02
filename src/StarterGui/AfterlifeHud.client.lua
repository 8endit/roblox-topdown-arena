local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("AfterlifeArcadeRemotes")
local updateHud = remotes:WaitForChild("UpdateHud")
local updateRun = remotes:WaitForChild("UpdateRun")
local updateRunState = remotes:WaitForChild("UpdateRunState")
local runSummary = remotes:WaitForChild("RunSummary")
local updateLoadout = remotes:WaitForChild("UpdateLoadout")
local announce = remotes:WaitForChild("Announce")

local gui = Instance.new("ScreenGui")
gui.Name = "AfterlifeHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0, 0)
panel.Position = UDim2.fromOffset(18, 18)
panel.Size = UDim2.fromOffset(330, 246)
panel.BackgroundColor3 = Color3.fromRGB(18, 21, 23)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(90, 210, 180)
stroke.Thickness = 1
stroke.Transparency = 0.25
stroke.Parent = panel

local function makeLabel(name, y, size, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = UDim2.fromOffset(16, y)
	label.Size = UDim2.new(1, -32, 0, size + 4)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextSize = size
	label.TextColor3 = color
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Text = ""
	label.Parent = panel
	return label
end

local title = makeLabel("Title", 10, 18, Color3.fromRGB(235, 245, 242))
title.Font = Enum.Font.GothamBold
title.Text = "Afterlife Arena"

local stageRoomLabel = makeLabel("StageRoom", 38, 15, Color3.fromRGB(180, 235, 220))
local waveLabel = makeLabel("Wave", 62, 15, Color3.fromRGB(180, 235, 220))
local enemyLabel = makeLabel("Enemies", 86, 15, Color3.fromRGB(240, 218, 145))
local mapLabel = makeLabel("Map", 110, 15, Color3.fromRGB(170, 206, 245))
local weaponLabel = makeLabel("Weapon", 134, 15, Color3.fromRGB(245, 245, 245))
local powerupLabel = makeLabel("Powerups", 158, 15, Color3.fromRGB(230, 205, 255))
local fateLabel = makeLabel("Fates", 178, 14, Color3.fromRGB(210, 180, 255))
local livesLabel = makeLabel("Lives", 198, 14, Color3.fromRGB(255, 196, 120))
local scoreLabel = makeLabel("Score", 218, 14, Color3.fromRGB(235, 235, 235))

local healthBack = Instance.new("Frame")
healthBack.Name = "HealthBack"
healthBack.AnchorPoint = Vector2.new(0.5, 1)
healthBack.Position = UDim2.new(0.5, 0, 1, -24)
healthBack.Size = UDim2.fromOffset(360, 16)
healthBack.BackgroundColor3 = Color3.fromRGB(35, 38, 40)
healthBack.BorderSizePixel = 0
healthBack.Parent = gui

local healthCorner = Instance.new("UICorner")
healthCorner.CornerRadius = UDim.new(0, 8)
healthCorner.Parent = healthBack

local healthFill = Instance.new("Frame")
healthFill.Name = "HealthFill"
healthFill.Size = UDim2.fromScale(1, 1)
healthFill.BackgroundColor3 = Color3.fromRGB(90, 210, 130)
healthFill.BorderSizePixel = 0
healthFill.Parent = healthBack

local healthFillCorner = Instance.new("UICorner")
healthFillCorner.CornerRadius = UDim.new(0, 8)
healthFillCorner.Parent = healthFill

local banner = Instance.new("TextLabel")
banner.Name = "Banner"
banner.AnchorPoint = Vector2.new(0.5, 0.5)
banner.Position = UDim2.fromScale(0.5, 0.24)
banner.Size = UDim2.fromOffset(760, 58)
banner.BackgroundTransparency = 1
banner.Font = Enum.Font.GothamBlack
banner.TextSize = 42
banner.TextColor3 = Color3.fromRGB(235, 245, 242)
banner.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
banner.TextStrokeTransparency = 1
banner.TextTransparency = 1
banner.Text = ""
banner.Parent = gui

local toast = Instance.new("TextLabel")
toast.Name = "Toast"
toast.AnchorPoint = Vector2.new(0.5, 0.5)
toast.Position = UDim2.fromScale(0.5, 0.34)
toast.Size = UDim2.fromOffset(460, 30)
toast.BackgroundTransparency = 1
toast.Font = Enum.Font.GothamBold
toast.TextSize = 24
toast.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
toast.TextStrokeTransparency = 1
toast.TextTransparency = 1
toast.Text = ""
toast.Parent = gui

local summary = Instance.new("TextLabel")
summary.Name = "RunSummary"
summary.AnchorPoint = Vector2.new(0.5, 0.5)
summary.Position = UDim2.fromScale(0.5, 0.5)
summary.Size = UDim2.fromOffset(560, 220)
summary.BackgroundColor3 = Color3.fromRGB(12, 14, 16)
summary.BackgroundTransparency = 0.12
summary.BorderSizePixel = 0
summary.Font = Enum.Font.GothamBold
summary.TextSize = 24
summary.TextColor3 = Color3.fromRGB(235, 245, 242)
summary.TextStrokeTransparency = 0.5
summary.TextWrapped = true
summary.TextTransparency = 1
summary.Visible = false
summary.Parent = gui

local summaryCorner = Instance.new("UICorner")
summaryCorner.CornerRadius = UDim.new(0, 8)
summaryCorner.Parent = summary

local bannerToken = 0
local function showBanner(text, color)
	bannerToken += 1
	local token = bannerToken
	banner.Text = text
	banner.TextColor3 = color or Color3.fromRGB(235, 245, 242)
	banner.TextTransparency = 0
	banner.TextStrokeTransparency = 0.4
	task.delay(1.2, function()
		if bannerToken ~= token then
			return
		end
		TweenService:Create(banner, TweenInfo.new(0.6), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
	end)
end

local toastToken = 0
local function showToast(text, color)
	toastToken += 1
	local token = toastToken
	toast.Text = "+ " .. text
	toast.TextColor3 = color or Color3.fromRGB(235, 245, 242)
	toast.TextTransparency = 0
	toast.TextStrokeTransparency = 0.4
	task.delay(1.0, function()
		if toastToken ~= token then
			return
		end
		TweenService:Create(toast, TweenInfo.new(0.55), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
	end)
end

local lastPayload = {
	wave = 0,
	enemies = 0,
	targetEnemies = 0,
	status = "Loading",
	map = "Depot",
	stage = 0,
	roomId = "",
	roomType = "StartRoom",
	roomName = "Start",
	fates = {},
}

local lastRunState = {
	state = "WAITING",
	lives = 0,
	kills = 0,
}

local lastLoadout = {
	weaponName = "Pistol",
	weaponRemaining = 0,
	weaponColor = Color3.fromRGB(245, 245, 245),
	powerups = {},
}

local function currentScore()
	local leaderstats = player:FindFirstChild("leaderstats")
	local score = leaderstats and leaderstats:FindFirstChild("Score")
	return score and score.Value or 0
end

local function updateLabels()
	stageRoomLabel.Text = string.format(
		"Stage: %s  |  Room: %s",
		tostring(lastPayload.stage),
		tostring(lastPayload.roomName)
	)
	waveLabel.Text = string.format("Wave: %s  |  %s", tostring(lastPayload.wave), tostring(lastPayload.status))
	enemyLabel.Text = string.format("Enemies: %s / %s", tostring(lastPayload.enemies), tostring(lastPayload.targetEnemies))
	mapLabel.Text = string.format("Map: %s", tostring(lastPayload.map))
	if lastLoadout.weaponRemaining > 0 then
		weaponLabel.Text = string.format("Weapon: %s (%ss)", tostring(lastLoadout.weaponName), tostring(lastLoadout.weaponRemaining))
	else
		weaponLabel.Text = string.format("Weapon: %s", tostring(lastLoadout.weaponName))
	end
	weaponLabel.TextColor3 = lastLoadout.weaponColor or Color3.fromRGB(245, 245, 245)

	local active = {}
	for _, powerup in ipairs(lastLoadout.powerups) do
		table.insert(active, string.format("%s %ss", tostring(powerup.name), tostring(powerup.remaining)))
	end
	powerupLabel.Text = "Powerups: " .. (#active > 0 and table.concat(active, ", ") or "-")

	local fates = {}
	for _, fate in ipairs(lastPayload.fates or {}) do
		local suffix = fate.count and fate.count > 1 and (" x" .. tostring(fate.count)) or ""
		table.insert(fates, tostring(fate.name) .. suffix)
	end
	fateLabel.Text = "Fates: " .. (#fates > 0 and table.concat(fates, ", ") or "-")
	livesLabel.Text = string.format(
		"Lives: %s  |  Kills: %s",
		tostring(lastRunState.lives),
		tostring(lastRunState.kills)
	)
	scoreLabel.Text = string.format("Score: %s", tostring(currentScore()))
end

updateHud.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end

	lastPayload.wave = payload.wave or lastPayload.wave
	lastPayload.enemies = payload.enemies or 0
	lastPayload.targetEnemies = payload.targetEnemies or 0
	lastPayload.status = payload.status or ""
	lastPayload.map = payload.map or lastPayload.map
	lastPayload.stage = payload.stage or lastPayload.stage
	lastPayload.roomId = payload.roomId or lastPayload.roomId
	lastPayload.roomType = payload.roomType or lastPayload.roomType
	lastPayload.roomName = payload.roomName or lastPayload.roomName
	lastPayload.fates = payload.fates or lastPayload.fates
	updateLabels()
end)

updateRun.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end

	lastPayload.stage = payload.stage or lastPayload.stage
	lastPayload.roomId = payload.roomId or lastPayload.roomId
	lastPayload.roomType = payload.roomType or lastPayload.roomType
	lastPayload.roomName = payload.roomName or lastPayload.roomName
	lastPayload.map = payload.map or lastPayload.map
	lastPayload.status = payload.status or lastPayload.status
	lastPayload.fates = payload.fates or lastPayload.fates
	updateLabels()
end)

updateRunState.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end

	lastRunState.state = payload.state or lastRunState.state
	lastRunState.lives = payload.lives or lastRunState.lives
	lastRunState.kills = payload.kills or lastRunState.kills
	updateLabels()
end)

runSummary.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end

	local fates = payload.fates or {}
	local fateText = #fates > 0 and table.concat(fates, ", ") or "-"
	summary.Text = string.format(
		"GAME OVER\nStage %s\nScore %s\nKills %s\nTime %ss\nFates: %s",
		tostring(payload.stage or 0),
		tostring(payload.score or 0),
		tostring(payload.kills or 0),
		tostring(payload.timeSeconds or 0),
		fateText
	)
	summary.Visible = true
	summary.TextTransparency = 0
	task.delay(payload.summarySeconds or 8, function()
		TweenService:Create(summary, TweenInfo.new(0.45), {TextTransparency = 1}):Play()
		task.delay(0.45, function()
			summary.Visible = false
		end)
	end)
end)

updateLoadout.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end

	lastLoadout.weaponName = payload.weaponName or lastLoadout.weaponName
	lastLoadout.weaponRemaining = payload.weaponRemaining or 0
	lastLoadout.weaponColor = payload.weaponColor or lastLoadout.weaponColor
	lastLoadout.powerups = payload.powerups or {}
	updateLabels()
end)

announce.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end

	if payload.style == "toast" then
		showToast(payload.text or "", payload.color)
	else
		showBanner(payload.text or "", payload.color)
	end
end)

RunService.RenderStepped:Connect(function()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local ratio = 0
		if humanoid.MaxHealth > 0 then
			ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
		end
		healthFill.Size = UDim2.fromScale(ratio, 1)
	end
	updateLabels()
end)
