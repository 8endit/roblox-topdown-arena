local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("AfterlifeArcade"):WaitForChild("Config"))

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local remotes = ReplicatedStorage:WaitForChild("AfterlifeArcadeRemotes")
local fireWeapon = remotes:WaitForChild("FireWeapon")
local dashRemote = remotes:WaitForChild("Dash")

local keysDown = {}
local firing = false
local lastShot = 0
local lastDash = 0

local function disableDefaultControls()
	local playerScripts = player:WaitForChild("PlayerScripts")
	local playerModule = playerScripts:WaitForChild("PlayerModule", 10)
	if not playerModule then
		return
	end

	local controls = require(playerModule):GetControls()
	controls:Disable()
end

local function getCharacterParts()
	local character = player.Character
	if not character then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or humanoid.Health <= 0 then
		return nil
	end

	return character, humanoid, root
end

local function getMouseWorldPosition()
	local mousePosition = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mousePosition.X, mousePosition.Y)
	local planeY = Config.Map.FloorY
	local denominator = ray.Direction.Y

	if math.abs(denominator) < 0.001 then
		return ray.Origin + ray.Direction * 80
	end

	local distance = (planeY - ray.Origin.Y) / denominator
	return ray.Origin + ray.Direction * distance
end

local function movementVector()
	local x = 0
	local z = 0

	if keysDown[Enum.KeyCode.A] or keysDown[Enum.KeyCode.Left] then
		x -= 1
	end
	if keysDown[Enum.KeyCode.D] or keysDown[Enum.KeyCode.Right] then
		x += 1
	end
	if keysDown[Enum.KeyCode.W] or keysDown[Enum.KeyCode.Up] then
		z -= 1
	end
	if keysDown[Enum.KeyCode.S] or keysDown[Enum.KeyCode.Down] then
		z += 1
	end

	local move = Vector3.new(x, 0, z)
	if move.Magnitude > 1 then
		return move.Unit
	end
	return move
end

local function currentDashCooldown()
	local character = player.Character
	return (character and character:GetAttribute("AfterlifeDashCooldown")) or Config.Player.DashCooldown
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.UserInputType == Enum.UserInputType.Keyboard then
		keysDown[input.KeyCode] = true
		if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.LeftShift then
			local now = os.clock()
			if now - lastDash >= currentDashCooldown() then
				lastDash = now
				local direction = movementVector()
				if direction.Magnitude <= 0.05 then
					local _, _, root = getCharacterParts()
					if root then
						direction = root.CFrame.LookVector
					end
				end
				dashRemote:FireServer(direction)
			end
		end
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
		firing = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		keysDown[input.KeyCode] = nil
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
		firing = false
	end
end)

camera.CameraType = Enum.CameraType.Scriptable
camera.FieldOfView = Config.Camera.FieldOfView

task.spawn(disableDefaultControls)

RunService:BindToRenderStep("AfterlifeTopDownController", Enum.RenderPriority.Camera.Value, function()
	local _, humanoid, root = getCharacterParts()
	if not humanoid or not root then
		return
	end

	local target = root.Position
	local cameraPosition = target + Vector3.new(0, Config.Camera.Height, Config.Camera.BackOffset)
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(cameraPosition, target)
	camera.Focus = CFrame.new(target)

	local aimPosition = getMouseWorldPosition()
	local flatAim = Vector3.new(aimPosition.X, root.Position.Y, aimPosition.Z)
	local aimDelta = flatAim - root.Position
	if aimDelta.Magnitude > 0.5 then
		root.CFrame = CFrame.lookAt(root.Position, root.Position + aimDelta.Unit)
	end

	humanoid:Move(movementVector(), false)

	if firing then
		local now = os.clock()
		if now - lastShot >= 0.03 then
			lastShot = now
			fireWeapon:FireServer(aimPosition)
		end
	end
end)
