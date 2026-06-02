local ReplicatedStorage = game:GetService("ReplicatedStorage")

local serverFolder = script.Parent
local MapBuilder = require(serverFolder:WaitForChild("MapBuilder"))
local EnemyService = require(serverFolder:WaitForChild("EnemyService"))
local PickupService = require(serverFolder:WaitForChild("PickupService"))
local PlayerService = require(serverFolder:WaitForChild("PlayerService"))
local RoomService = require(serverFolder:WaitForChild("RoomService"))
local WaveService = require(serverFolder:WaitForChild("WaveService"))
local WeaponService = require(serverFolder:WaitForChild("WeaponService"))

local function ensureRemoteFolder()
	local folder = ReplicatedStorage:FindFirstChild("AfterlifeArcadeRemotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "AfterlifeArcadeRemotes"
		folder.Parent = ReplicatedStorage
	end

	local fireWeapon = folder:FindFirstChild("FireWeapon")
	if not fireWeapon then
		fireWeapon = Instance.new("RemoteEvent")
		fireWeapon.Name = "FireWeapon"
		fireWeapon.Parent = folder
	end

	local updateHud = folder:FindFirstChild("UpdateHud")
	if not updateHud then
		updateHud = Instance.new("RemoteEvent")
		updateHud.Name = "UpdateHud"
		updateHud.Parent = folder
	end

	local updateRun = folder:FindFirstChild("UpdateRun")
	if not updateRun then
		updateRun = Instance.new("RemoteEvent")
		updateRun.Name = "UpdateRun"
		updateRun.Parent = folder
	end

	local updateLoadout = folder:FindFirstChild("UpdateLoadout")
	if not updateLoadout then
		updateLoadout = Instance.new("RemoteEvent")
		updateLoadout.Name = "UpdateLoadout"
		updateLoadout.Parent = folder
	end

	local announce = folder:FindFirstChild("Announce")
	if not announce then
		announce = Instance.new("RemoteEvent")
		announce.Name = "Announce"
		announce.Parent = folder
	end

	local dash = folder:FindFirstChild("Dash")
	if not dash then
		dash = Instance.new("RemoteEvent")
		dash.Name = "Dash"
		dash.Parent = folder
	end

	return folder
end

math.randomseed(os.time())

local remotes = ensureRemoteFolder()

MapBuilder.Build()
PlayerService.Init(remotes)
EnemyService.Init()
WeaponService.Init(remotes, EnemyService)
PickupService.Init(WeaponService, remotes)
WaveService.Init(remotes, EnemyService, PlayerService, MapBuilder, PickupService)
WaveService.SetRoomService(RoomService)
RoomService.Init(remotes, MapBuilder, PlayerService, PickupService, WaveService, WeaponService)
