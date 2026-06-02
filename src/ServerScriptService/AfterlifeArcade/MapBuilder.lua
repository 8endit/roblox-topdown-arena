local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("AfterlifeArcade"):WaitForChild("Config"))

local MapBuilder = {}
local currentLayoutId = Config.MapRotation[1]

local function makePart(parent, name, size, cframe, material, color, canCollide)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = canCollide ~= false
	part.Size = size
	part.CFrame = cframe
	part.Material = material
	part.Color = color
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function addSpawn(folder, name, position)
	local marker = Instance.new("Part")
	marker.Name = name
	marker.Anchored = true
	marker.CanCollide = false
	marker.Transparency = 1
	marker.Size = Vector3.new(4, 1, 4)
	marker.Position = position
	marker.Parent = folder
	return marker
end

local function resolveLayout(layoutId)
	local id = layoutId or currentLayoutId or Config.MapRotation[1]
	return id, Config.MapLayouts[id] or Config.MapLayouts[Config.MapRotation[1]]
end

function MapBuilder.Build(layoutId)
	local resolvedId, layout = resolveLayout(layoutId)
	currentLayoutId = resolvedId

	local oldMap = Workspace:FindFirstChild(Config.Map.Name)
	if oldMap then
		oldMap:Destroy()
	end

	local map = Instance.new("Folder")
	map.Name = Config.Map.Name
	map:SetAttribute("LayoutId", resolvedId)
	map:SetAttribute("LayoutName", layout.DisplayName or resolvedId)
	map.Parent = Workspace

	local arena = Instance.new("Folder")
	arena.Name = "Arena"
	arena.Parent = map

	local spawns = Instance.new("Folder")
	spawns.Name = "EnemySpawns"
	spawns.Parent = map

	local cover = Instance.new("Folder")
	cover.Name = "Cover"
	cover.Parent = map

	local width = layout.Width or Config.Map.Width
	local depth = layout.Depth or Config.Map.Depth
	local wallHeight = Config.Map.WallHeight
	local wallThickness = Config.Map.WallThickness
	local floorY = Config.Map.FloorY

	makePart(
		arena,
		"Floor",
		Vector3.new(width, 1, depth),
		CFrame.new(0, floorY - 0.5, 0),
		Enum.Material.Concrete,
		layout.FloorColor or Color3.fromRGB(38, 43, 45),
		true
	)

	makePart(arena, "NorthWall", Vector3.new(width + wallThickness * 2, wallHeight, wallThickness), CFrame.new(0, wallHeight / 2, -depth / 2), Enum.Material.Metal, Color3.fromRGB(55, 65, 70), true)
	makePart(arena, "SouthWall", Vector3.new(width + wallThickness * 2, wallHeight, wallThickness), CFrame.new(0, wallHeight / 2, depth / 2), Enum.Material.Metal, Color3.fromRGB(55, 65, 70), true)
	makePart(arena, "WestWall", Vector3.new(wallThickness, wallHeight, depth), CFrame.new(-width / 2, wallHeight / 2, 0), Enum.Material.Metal, Color3.fromRGB(55, 65, 70), true)
	makePart(arena, "EastWall", Vector3.new(wallThickness, wallHeight, depth), CFrame.new(width / 2, wallHeight / 2, 0), Enum.Material.Metal, Color3.fromRGB(55, 65, 70), true)

	for _, data in ipairs(layout.Cover or {}) do
		makePart(cover, data[1], data[2], CFrame.new(data[3]), Enum.Material.Basalt, Color3.fromRGB(77, 83, 86), true)
	end

	for index, position in ipairs(layout.Spawns or {}) do
		addSpawn(spawns, "Spawn" .. tostring(index), position)
	end

	local playerSpawn = Instance.new("SpawnLocation")
	playerSpawn.Name = "PlayerSpawn"
	playerSpawn.Anchored = true
	playerSpawn.Neutral = true
	playerSpawn.Duration = 0
	playerSpawn.Size = Vector3.new(8, 1, 8)
	playerSpawn.Position = Config.Map.PlayerSpawn
	playerSpawn.Material = Enum.Material.Neon
	playerSpawn.Color = Color3.fromRGB(80, 190, 160)
	playerSpawn.Parent = map

	local light = Instance.new("PointLight")
	light.Name = "ArenaLight"
	light.Range = 110
	light.Brightness = 3
	light.Color = Color3.fromRGB(210, 238, 255)
	light.Parent = playerSpawn

	Workspace:SetAttribute("AfterlifeArcadeReady", true)
	Workspace:SetAttribute("AfterlifeMapLayout", layout.DisplayName or resolvedId)
	return map
end

function MapBuilder.GetCurrentLayoutId()
	return currentLayoutId
end

return MapBuilder
