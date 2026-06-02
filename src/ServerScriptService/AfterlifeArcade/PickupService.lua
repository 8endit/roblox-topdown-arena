local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("AfterlifeArcade"):WaitForChild("Config"))

local PickupService = {}

local pickupsFolder
local weaponService
local remotes

local function getPickupsFolder()
	if pickupsFolder and pickupsFolder.Parent then
		return pickupsFolder
	end

	pickupsFolder = Workspace:FindFirstChild("AfterlifePickups")
	if not pickupsFolder then
		pickupsFolder = Instance.new("Folder")
		pickupsFolder.Name = "AfterlifePickups"
		pickupsFolder.Parent = Workspace
	end

	return pickupsFolder
end

local function weightedChoice(entries)
	local totalWeight = 0
	for _, entry in ipairs(entries) do
		totalWeight += entry.Weight
	end

	if totalWeight <= 0 then
		return entries[1] and entries[1].Id or nil
	end

	local roll = math.random() * totalWeight
	local cursor = 0
	for _, entry in ipairs(entries) do
		cursor += entry.Weight
		if roll <= cursor then
			return entry.Id
		end
	end

	return entries[#entries].Id
end

-- Tier waehlen; mit steigender Welle leicht hoeherwertig.
local function chooseTier(weights, wave)
	local entries = {}
	for _, entry in ipairs(weights) do
		local weight = entry.Weight
		if entry.Tier == "Epic" then
			weight += math.floor((wave or 1) / 4)
		elseif entry.Tier == "Rare" then
			weight += math.floor((wave or 1) / 3)
		end
		table.insert(entries, {Id = entry.Tier, Weight = weight})
	end
	return weightedChoice(entries)
end

local function pickupColor(kind, id)
	if kind == "Weapon" then
		return (Config.Weapons[id] and Config.Weapons[id].Color) or Color3.fromRGB(255, 222, 96)
	end
	return (Config.Powerups[id] and Config.Powerups[id].Color) or Color3.fromRGB(120, 220, 255)
end

local function pickupName(kind, id)
	if kind == "Weapon" then
		return (Config.Weapons[id] and Config.Weapons[id].DisplayName) or id
	end
	return (Config.Powerups[id] and Config.Powerups[id].DisplayName) or id
end

local function getArenaInfo()
	local map = Workspace:FindFirstChild(Config.Map.Name)
	if not map then
		return nil
	end

	local halfX = Config.Map.Width / 2
	local halfZ = Config.Map.Depth / 2
	local arena = map:FindFirstChild("Arena")
	local floor = arena and arena:FindFirstChild("Floor")
	if floor then
		halfX = floor.Size.X / 2
		halfZ = floor.Size.Z / 2
	end

	local covers = {}
	local coverFolder = map:FindFirstChild("Cover")
	if coverFolder then
		for _, child in ipairs(coverFolder:GetChildren()) do
			if child:IsA("BasePart") then
				table.insert(covers, child)
			end
		end
	end

	return halfX, halfZ, covers
end

local function overlapsCover(x, z, covers, radius)
	for _, cover in ipairs(covers) do
		local center = cover.Position
		if math.abs(x - center.X) < cover.Size.X / 2 + radius and math.abs(z - center.Z) < cover.Size.Z / 2 + radius then
			return cover
		end
	end
	return nil
end

-- Drops nicht in Wand/Deckung fallen lassen: in die Arena clampen und
-- aus ueberlappender Deckung entlang der kuerzesten Achse herausschieben.
local function adjustDropPosition(position)
	local halfX, halfZ, covers = getArenaInfo()
	if not halfX then
		return position
	end

	local radius = Config.Loot.BaseSize * 0.5 + Config.Loot.CoverBuffer
	local margin = Config.Loot.DropMargin
	local limX = math.max(halfX - margin, 4)
	local limZ = math.max(halfZ - margin, 4)
	local x = math.clamp(position.X, -limX, limX)
	local z = math.clamp(position.Z, -limZ, limZ)

	for _ = 1, 8 do
		local hit = overlapsCover(x, z, covers, radius)
		if not hit then
			break
		end

		local dx = x - hit.Position.X
		local dz = z - hit.Position.Z
		if math.abs(dx) < 0.01 and math.abs(dz) < 0.01 then
			dx = 1
		end

		local penX = (hit.Size.X / 2 + radius) - math.abs(dx)
		local penZ = (hit.Size.Z / 2 + radius) - math.abs(dz)
		if penX <= penZ then
			x = x + (dx >= 0 and (penX + 0.2) or -(penX + 0.2))
		else
			z = z + (dz >= 0 and (penZ + 0.2) or -(penZ + 0.2))
		end

		x = math.clamp(x, -limX, limX)
		z = math.clamp(z, -limZ, limZ)
	end

	return Vector3.new(x, position.Y, z)
end

local function addBillboard(part, text, color)
	local gui = Instance.new("BillboardGui")
	gui.Name = "PickupLabel"
	gui.AlwaysOnTop = true
	gui.Size = UDim2.fromOffset(124, 28)
	gui.StudsOffset = Vector3.new(0, 3.6, 0)
	gui.Parent = part

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.35
	label.TextSize = 14
	label.Parent = gui
end

local function announcePickup(player, kind, id, rarityId)
	if not remotes then
		return
	end
	local announce = remotes:FindFirstChild("Announce")
	if not announce then
		return
	end

	local rarity = Config.Rarities[rarityId] or Config.Rarities.Common
	announce:FireClient(player, {
		style = "toast",
		text = rarity.Prefix .. pickupName(kind, id),
		color = rarity.Color,
	})
end

local function createPickup(kind, id, position, rarityId)
	local rarity = Config.Rarities[rarityId] or Config.Rarities.Common
	local size = Config.Loot.BaseSize * rarity.SizeScale

	local part = Instance.new("Part")
	part.Name = kind .. "_" .. id
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(size, size, size)
	part.Position = position + Vector3.new(0, 2.4, 0)
	part.Material = Enum.Material.Neon
	part.Color = pickupColor(kind, id)
	part:SetAttribute("PickupKind", kind)
	part:SetAttribute("PickupId", id)
	part:SetAttribute("Rarity", rarityId)
	part:SetAttribute("Consumed", false)
	part.Parent = getPickupsFolder()

	local light = Instance.new("PointLight")
	light.Name = "PickupGlow"
	light.Range = rarity.GlowRange
	light.Brightness = rarity.GlowBrightness
	light.Color = rarity.Color
	light.Parent = part

	-- Rarity-Aura: Outline scheint durch Deckung, hilft Loot zu finden.
	local aura = Instance.new("Highlight")
	aura.Name = "RarityAura"
	aura.FillColor = rarity.Color
	aura.FillTransparency = 0.6
	aura.OutlineColor = rarity.Color
	aura.OutlineTransparency = 0.1
	aura.DepthMode = Enum.HighlightDepthMode.Occluded
	aura.Adornee = part
	aura.Parent = part

	addBillboard(part, rarity.Prefix .. pickupName(kind, id), rarity.Color)

	part.Touched:Connect(function(hit)
		if part:GetAttribute("Consumed") then
			return
		end

		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then
			return
		end

		part:SetAttribute("Consumed", true)
		local pickupKind = part:GetAttribute("PickupKind")
		local pickupId = part:GetAttribute("PickupId")
		local applied = false

		if pickupKind == "Weapon" then
			applied = weaponService.EquipWeapon(player, pickupId)
		elseif pickupKind == "Powerup" then
			applied = weaponService.ApplyPowerup(player, pickupId)
		end

		if applied then
			announcePickup(player, pickupKind, pickupId, part:GetAttribute("Rarity"))
			part:Destroy()
		else
			part:SetAttribute("Consumed", false)
		end
	end)

	Debris:AddItem(part, Config.Loot.PickupLifetime)
	return part
end

local function startMagnetLoop()
	RunService.Heartbeat:Connect(function(dt)
		local folder = pickupsFolder
		if not folder or not folder.Parent then
			return
		end

		local pullers = {}
		for _, player in ipairs(Players:GetPlayers()) do
			if weaponService and weaponService.IsPowerupActive(player, "Magnet") then
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if root then
					table.insert(pullers, root)
				end
			end
		end

		if #pullers == 0 then
			return
		end

		local range = Config.Loot.MagnetRange
		local speed = Config.Loot.MagnetSpeed
		for _, part in ipairs(folder:GetChildren()) do
			if part:IsA("BasePart") and not part:GetAttribute("Consumed") then
				local best, bestDistance
				for _, root in ipairs(pullers) do
					local distance = (root.Position - part.Position).Magnitude
					if distance <= range and (not bestDistance or distance < bestDistance) then
						best = root
						bestDistance = distance
					end
				end

				if best then
					local target = Vector3.new(best.Position.X, part.Position.Y, best.Position.Z)
					local toTarget = target - part.Position
					if toTarget.Magnitude > 0.05 then
						local step = math.min(speed * dt, toTarget.Magnitude)
						part.Position = part.Position + toTarget.Unit * step
					end
				end
			end
		end
	end)
end

function PickupService.Init(weapons, remoteFolder)
	weaponService = weapons
	remotes = remoteFolder
	getPickupsFolder()
	startMagnetLoop()
end

function PickupService.ClearAll()
	if pickupsFolder and pickupsFolder.Parent then
		for _, child in ipairs(pickupsFolder:GetChildren()) do
			child:Destroy()
		end
	end
end

function PickupService.TryDropForEnemy(enemyTypeId, position, wave, dropChance)
	if not position then
		return nil
	end

	local typeConfig = Config.EnemyTypes[enemyTypeId]
	local isBoss = typeConfig ~= nil and typeConfig.Boss == true
	local tierWeights

	if isBoss then
		tierWeights = Config.Loot.BossTierWeights
	else
		local chance = dropChance or 0
		if wave and wave >= 6 then
			chance += Config.Loot.LateWaveDropBonus
		end
		if math.random() > chance then
			return nil
		end
		tierWeights = Config.Loot.TierWeights
	end

	local tierId = chooseTier(tierWeights, wave)
	local tier = Config.Loot.Tiers[tierId] or Config.Loot.Tiers.Common

	local kind = "Powerup"
	local pool = tier.Powerups
	if math.random() < (tier.WeaponChance or 0) then
		kind = "Weapon"
		pool = tier.Weapons
	end

	local id = weightedChoice(pool)
	if not id then
		return nil
	end

	return createPickup(kind, id, adjustDropPosition(position), tierId)
end

function PickupService.SpawnPowerup(id, position, rarityId)
	return createPickup("Powerup", id, adjustDropPosition(position), rarityId or "Rare")
end

function PickupService.SpawnWeapon(id, position, rarityId)
	return createPickup("Weapon", id, adjustDropPosition(position), rarityId or "Rare")
end

return PickupService
