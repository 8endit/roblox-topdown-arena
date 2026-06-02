local Config = {}

Config.Map = {
	Name = "AfterlifeArcadeMap",
	Width = 160,
	Depth = 120,
	FloorY = 0,
	WallHeight = 14,
	WallThickness = 4,
	PlayerSpawn = Vector3.new(0, 4, 0),
}

Config.MapLayouts = {
	Depot = {
		DisplayName = "Depot",
		Dynamic = "Gemischte Deckung, mittlere Distanzen",
		Width = 160,
		Depth = 120,
		FloorColor = Color3.fromRGB(38, 43, 45),
		Cover = {
			{"CentralBlockA", Vector3.new(18, 8, 8), Vector3.new(-22, 4, -8)},
			{"CentralBlockB", Vector3.new(18, 8, 8), Vector3.new(24, 4, 10)},
			{"LongCoverNorth", Vector3.new(34, 7, 5), Vector3.new(20, 3.5, -34)},
			{"LongCoverSouth", Vector3.new(34, 7, 5), Vector3.new(-24, 3.5, 35)},
			{"PillarNW", Vector3.new(8, 9, 8), Vector3.new(-55, 4.5, -36)},
			{"PillarSE", Vector3.new(8, 9, 8), Vector3.new(55, 4.5, 36)},
		},
		Spawns = {
			Vector3.new(-64, 2, -44),
			Vector3.new(64, 2, -44),
			Vector3.new(-64, 2, 44),
			Vector3.new(64, 2, 44),
			Vector3.new(-72, 2, 0),
			Vector3.new(72, 2, 0),
		},
	},
	Courtyard = {
		DisplayName = "Courtyard",
		Dynamic = "Offen, lange Sichtlinien",
		Width = 176,
		Depth = 132,
		FloorColor = Color3.fromRGB(42, 51, 45),
		Cover = {
			{"NorthStatue", Vector3.new(10, 10, 10), Vector3.new(0, 5, -38)},
			{"SouthStatue", Vector3.new(10, 10, 10), Vector3.new(0, 5, 38)},
			{"WestBench", Vector3.new(42, 5, 5), Vector3.new(-42, 2.5, 0)},
			{"EastBench", Vector3.new(42, 5, 5), Vector3.new(42, 2.5, 0)},
			{"CornerNW", Vector3.new(16, 7, 16), Vector3.new(-58, 3.5, -42)},
			{"CornerSE", Vector3.new(16, 7, 16), Vector3.new(58, 3.5, 42)},
		},
		Spawns = {
			Vector3.new(-74, 2, -50),
			Vector3.new(74, 2, -50),
			Vector3.new(-74, 2, 50),
			Vector3.new(74, 2, 50),
			Vector3.new(0, 2, -58),
			Vector3.new(0, 2, 58),
		},
	},
	Bunker = {
		DisplayName = "Bunker",
		Dynamic = "Enge Chokepoints",
		Width = 150,
		Depth = 128,
		FloorColor = Color3.fromRGB(36, 39, 48),
		Cover = {
			{"NorthChokeLeft", Vector3.new(42, 9, 6), Vector3.new(-34, 4.5, -28)},
			{"NorthChokeRight", Vector3.new(42, 9, 6), Vector3.new(34, 4.5, -28)},
			{"SouthChokeLeft", Vector3.new(42, 9, 6), Vector3.new(-34, 4.5, 28)},
			{"SouthChokeRight", Vector3.new(42, 9, 6), Vector3.new(34, 4.5, 28)},
			{"CoreA", Vector3.new(12, 10, 18), Vector3.new(-16, 5, 0)},
			{"CoreB", Vector3.new(12, 10, 18), Vector3.new(16, 5, 0)},
		},
		Spawns = {
			Vector3.new(-62, 2, -46),
			Vector3.new(62, 2, -46),
			Vector3.new(-62, 2, 46),
			Vector3.new(62, 2, 46),
			Vector3.new(-68, 2, 0),
			Vector3.new(68, 2, 0),
		},
	},
	Crucible = {
		DisplayName = "Crucible",
		Dynamic = "Riskante offene Mitte, Deckung am Rand",
		Width = 168,
		Depth = 140,
		FloorColor = Color3.fromRGB(48, 40, 52),
		Cover = {
			{"RingNW", Vector3.new(11, 9, 11), Vector3.new(-30, 4.5, -26)},
			{"RingNE", Vector3.new(11, 9, 11), Vector3.new(30, 4.5, -26)},
			{"RingSW", Vector3.new(11, 9, 11), Vector3.new(-30, 4.5, 26)},
			{"RingSE", Vector3.new(11, 9, 11), Vector3.new(30, 4.5, 26)},
			{"GateWest", Vector3.new(6, 8, 30), Vector3.new(-58, 4, 0)},
			{"GateEast", Vector3.new(6, 8, 30), Vector3.new(58, 4, 0)},
			{"CorePillar", Vector3.new(7, 11, 7), Vector3.new(0, 5.5, 0)},
		},
		Spawns = {
			Vector3.new(-72, 2, -56),
			Vector3.new(72, 2, -56),
			Vector3.new(-72, 2, 56),
			Vector3.new(72, 2, 56),
			Vector3.new(0, 2, -62),
			Vector3.new(0, 2, 62),
		},
	},
	Galleries = {
		DisplayName = "Galleries",
		Dynamic = "Enges Pfeilerlabyrinth, kurze Lanes",
		Width = 150,
		Depth = 120,
		FloorColor = Color3.fromRGB(40, 44, 40),
		Cover = {
			{"PillarA", Vector3.new(9, 9, 9), Vector3.new(-40, 4.5, -30)},
			{"PillarB", Vector3.new(9, 9, 9), Vector3.new(0, 4.5, -30)},
			{"PillarC", Vector3.new(9, 9, 9), Vector3.new(40, 4.5, -30)},
			{"PillarD", Vector3.new(9, 9, 9), Vector3.new(-40, 4.5, 30)},
			{"PillarE", Vector3.new(9, 9, 9), Vector3.new(0, 4.5, 30)},
			{"PillarF", Vector3.new(9, 9, 9), Vector3.new(40, 4.5, 30)},
			{"PillarG", Vector3.new(9, 9, 9), Vector3.new(-20, 4.5, 0)},
			{"PillarH", Vector3.new(9, 9, 9), Vector3.new(20, 4.5, 0)},
		},
		Spawns = {
			Vector3.new(-66, 2, -48),
			Vector3.new(66, 2, -48),
			Vector3.new(-66, 2, 48),
			Vector3.new(66, 2, 48),
			Vector3.new(0, 2, -52),
			Vector3.new(0, 2, 52),
		},
	},
}

Config.MapRotation = {"Depot", "Courtyard", "Bunker", "Crucible", "Galleries"}

Config.Player = {
	WalkSpeed = 24,
	MaxHealth = 100,
	DashDistance = 24,
	DashCooldown = 1.15,
	DashIFrames = 0.18,
	DashGhostLifetime = 0.18,
}

Config.Camera = {
	Height = 72,
	BackOffset = 8,
	FieldOfView = 48,
}

-- Geteilte Tracer-Optik (waffenspezifische Werte koennen dies ueberschreiben).
Config.Weapon = {
	TracerLifetime = 0.07,
	TracerWidth = 0.18,
}

-- Rollen-Notiz pro Waffe: keine ist strikt besser, jede gewinnt eine andere Achse.
-- Pistol  : unbegrenzte Startwaffe, solide Mitteldistanz
-- SMG     : hoechste Dauer-DPS, kurze Reichweite, hohe Streuung
-- Shotgun : brutaler Nahkampf-Burst, faellt auf Distanz ab
-- Rifle   : praezise Langdistanz, hoher Einzelschaden gegen Bruiser/Tank
-- BurstRifle: 3er-Burst, front-loaded Schaden gegen mittlere Ziele
-- Beam    : durchschlaegt mehrere Gegner (Schwarm-Konter), praezise
Config.Weapons = {
	Pistol = {
		DisplayName = "Pistol",
		Damage = 26,
		FireRate = 0.16,
		Range = 150,
		Pellets = 1,
		SpreadDegrees = 1.2,
		DropSeconds = 0,
		Color = Color3.fromRGB(255, 222, 96),
	},
	SMG = {
		DisplayName = "SMG",
		Damage = 16,
		FireRate = 0.06,
		Range = 110,
		Pellets = 1,
		SpreadDegrees = 5,
		DropSeconds = 18,
		Color = Color3.fromRGB(105, 205, 255),
	},
	Shotgun = {
		DisplayName = "Shotgun",
		Damage = 14,
		FireRate = 0.6,
		Range = 75,
		Pellets = 8,
		SpreadDegrees = 14,
		DropSeconds = 16,
		Color = Color3.fromRGB(255, 168, 92),
	},
	Rifle = {
		DisplayName = "Rifle",
		Damage = 62,
		FireRate = 0.32,
		Range = 200,
		Pellets = 1,
		SpreadDegrees = 0.6,
		DropSeconds = 20,
		Color = Color3.fromRGB(160, 240, 170),
	},
	BurstRifle = {
		DisplayName = "Burst Rifle",
		Damage = 30,
		FireRate = 0.5,
		Range = 150,
		Pellets = 1,
		SpreadDegrees = 2,
		BurstCount = 3,
		BurstDelay = 0.06,
		DropSeconds = 18,
		Color = Color3.fromRGB(255, 140, 210),
	},
	Beam = {
		DisplayName = "Beam",
		Damage = 22,
		FireRate = 0.09,
		Range = 170,
		Pellets = 1,
		SpreadDegrees = 0.5,
		Pierce = 4,
		TracerWidth = 0.42,
		TracerLifetime = 0.1,
		DropSeconds = 16,
		Color = Color3.fromRGB(120, 255, 235),
	},
}

Config.EnemyTypes = {
	Runner = {
		DisplayName = "Runner",
		Role = "Schwarmdruck: billig, schnell, in Masse",
		Cost = 1,
		MinWave = 1,
		Health = 50,
		HealthPerWave = 9,
		Speed = 18,
		SpeedPerWave = 0.3,
		Damage = 8,
		AttackRange = 4,
		AttackCooldown = 0.55,
		Size = Vector3.new(3.1, 4.2, 3.1),
		Color = Color3.fromRGB(220, 70, 78),
		Score = 20,
		DropChance = 0.05,
	},
	Bruiser = {
		DisplayName = "Bruiser",
		Role = "Raumkontrolle: langsam, zaeh, blockiert Lanes",
		Cost = 3,
		MinWave = 2,
		Health = 165,
		HealthPerWave = 20,
		Speed = 8,
		SpeedPerWave = 0.14,
		Damage = 20,
		AttackRange = 5,
		AttackCooldown = 1.05,
		Size = Vector3.new(5.8, 6.4, 5.8),
		Color = Color3.fromRGB(190, 102, 54),
		Score = 55,
		DropChance = 0.16,
	},
	Spitter = {
		DisplayName = "Spitter",
		Role = "Distanzdruck: kitet weg, telegrafierte Fernangriffe",
		Cost = 4,
		MinWave = 3,
		Health = 88,
		HealthPerWave = 12,
		Speed = 11,
		SpeedPerWave = 0.12,
		Damage = 14,
		AttackMode = "Ranged",
		AttackRange = 58,
		PreferredRange = 36,
		AttackCooldown = 1.8,
		ChargeTime = 0.5,
		Size = Vector3.new(3.8, 5.2, 3.8),
		Color = Color3.fromRGB(84, 202, 118),
		Score = 70,
		DropChance = 0.18,
	},
	Exploder = {
		DisplayName = "Exploder",
		Role = "Selbstmord-Bombe: sichtbare Warnphase vor Explosion",
		Cost = 4,
		MinWave = 4,
		Health = 70,
		HealthPerWave = 11,
		Speed = 14,
		SpeedPerWave = 0.22,
		Damage = 38,
		AttackMode = "Explode",
		AttackRange = 9,
		BlastRadius = 18,
		WarnTime = 0.75,
		AttackCooldown = 0.1,
		Size = Vector3.new(4.2, 5.2, 4.2),
		Color = Color3.fromRGB(236, 185, 68),
		Score = 80,
		DropChance = 0.22,
	},
	Tank = {
		DisplayName = "Tank",
		Role = "Boss: Healthbar, hoher Score, garantierter Top-Drop",
		Boss = true,
		Cost = 10,
		MinWave = 5,
		BossEvery = 5,
		Health = 520,
		HealthPerWave = 48,
		Speed = 6.8,
		SpeedPerWave = 0.12,
		Damage = 26,
		AttackRange = 6,
		AttackCooldown = 1.2,
		Size = Vector3.new(7.8, 8, 7.8),
		Color = Color3.fromRGB(138, 82, 196),
		Score = 220,
		DropChance = 1,
	},
}

Config.EnemyMovement = {
	SeparationRadius = 7,
	SeparationStrength = 0.72,
	MaxSeparationNeighbors = 6,
}

Config.Waves = {
	StartDelay = 4,
	BetweenWaveDelay = 5,
	SpawnInterval = 0.55,
	BaseCount = 8,
	CountPerWave = 4,
	BaseBudget = 9,
	BudgetPerWave = 5,
	MapChangeEvery = 3,
}

Config.Rooms = {
	StartRoom = {
		DisplayName = "Start",
		Clear = "instant",
		Layouts = {"Depot"},
		BudgetMult = 0,
	},
	CombatRoom = {
		DisplayName = "Combat",
		Clear = "killAll",
		Layouts = {"Depot", "Bunker", "Courtyard"},
		BudgetMult = 1,
	},
	RushRoom = {
		DisplayName = "Rush",
		Clear = "killAll",
		Layouts = {"Courtyard", "Crucible"},
		BudgetMult = 1.35,
		EnemyWeights = {Runner = 12, Exploder = 2},
	},
	TreasureRoom = {
		DisplayName = "Treasure",
		Clear = "instant",
		Layouts = {"Galleries", "Bunker"},
		BudgetMult = 0,
		PrePlacedLoot = {Rare = 1},
	},
	FateRoom = {
		DisplayName = "Fate",
		Clear = "chooseFate",
		Layouts = {"Galleries"},
		BudgetMult = 0,
	},
	BossRoom = {
		DisplayName = "Boss",
		Clear = "killAll",
		Layouts = {"Courtyard", "Crucible"},
		BudgetMult = 0.75,
		Boss = "Tank",
		Terminal = true,
	},
	ExitRoom = {
		DisplayName = "Exit",
		Clear = "killAll",
		Layouts = {"Depot", "Bunker"},
		BudgetMult = 0.6,
		Terminal = true,
	},
}

Config.Stages = {
	StartDelay = 3,
	Templates = {
		[1] = {
			start = "s",
			nodes = {
				s = {type = "StartRoom", next = {c1 = "E"}},
				c1 = {type = "CombatRoom", next = {c2 = "E", t = "N"}},
				t = {type = "TreasureRoom", next = {c2 = "E"}},
				c2 = {type = "CombatRoom", next = {x = "E"}},
				x = {type = "ExitRoom", next = {}, terminal = true},
			},
		},
		[2] = {
			start = "s",
			nodes = {
				s = {type = "StartRoom", next = {c1 = "E"}},
				c1 = {type = "CombatRoom", next = {r = "E", f = "N"}},
				f = {type = "FateRoom", next = {r = "E"}},
				r = {type = "RushRoom", next = {x = "E", t = "S"}},
				t = {type = "TreasureRoom", next = {x = "E"}},
				x = {type = "ExitRoom", next = {}, terminal = true},
			},
		},
		[3] = {
			start = "s",
			nodes = {
				s = {type = "StartRoom", next = {c1 = "E"}},
				c1 = {type = "CombatRoom", next = {c2 = "E", f = "N"}},
				f = {type = "FateRoom", next = {c2 = "E"}},
				c2 = {type = "CombatRoom", next = {r = "E", t = "S"}},
				t = {type = "TreasureRoom", next = {r = "E"}},
				r = {type = "RushRoom", next = {b = "E"}},
				b = {type = "BossRoom", next = {}, terminal = true},
			},
		},
	},
}

Config.Fates = {
	OfferCount = 3,
	PedestalSpacing = 12,
	PedestalColor = Color3.fromRGB(190, 110, 255),
	Pool = {
		FleetSoul = {
			DisplayName = "Fleet Soul",
			Description = "Dash cooldown down",
			Color = Color3.fromRGB(110, 220, 255),
			Unique = false,
		},
		HeavyHands = {
			DisplayName = "Heavy Hands",
			Description = "More damage, less speed",
			Color = Color3.fromRGB(255, 170, 90),
			Unique = false,
		},
		GlassFlame = {
			DisplayName = "Glass Flame",
			Description = "More damage, lower max health",
			Color = Color3.fromRGB(255, 92, 92),
			Unique = false,
		},
		PiercingRite = {
			DisplayName = "Piercing Rite",
			Description = "Shots pierce one more target",
			Color = Color3.fromRGB(170, 130, 255),
			Unique = false,
		},
	},
}

Config.Gates = {
	Radius = 7,
	Color = Color3.fromRGB(80, 180, 255),
	ColorsByTargetType = {
		CombatRoom = Color3.fromRGB(120, 230, 200),
		RushRoom = Color3.fromRGB(255, 170, 90),
		TreasureRoom = Color3.fromRGB(255, 220, 100),
		FateRoom = Color3.fromRGB(190, 110, 255),
		BossRoom = Color3.fromRGB(255, 92, 72),
		ExitRoom = Color3.fromRGB(80, 230, 210),
	},
}

Config.StageTeleporter = {
	TeleporterRadius = 7,
	TeleporterLifetime = 120,
	TeleporterColor = Color3.fromRGB(80, 230, 210),
	BossTeleporterColor = Color3.fromRGB(255, 122, 92),
}

Config.Spawning = {
	MinPlayerDistance = 52,
	PreferFarthestCount = 3,
}

Config.Rewards = {
	ScorePerEnemy = 25,
}

Config.Powerups = {
	Health = {
		DisplayName = "Medkit",
		Duration = 0,
		Heal = 40,
		Color = Color3.fromRGB(96, 238, 128),
	},
	DamageBoost = {
		DisplayName = "Damage Boost",
		Duration = 12,
		DamageMultiplier = 1.5,
		Color = Color3.fromRGB(255, 92, 92),
	},
	RapidFire = {
		DisplayName = "Rapid Fire",
		Duration = 10,
		FireRateMultiplier = 0.6,
		Color = Color3.fromRGB(255, 218, 88),
	},
	SpeedBoost = {
		DisplayName = "Speed Boost",
		Duration = 12,
		WalkSpeedBonus = 8,
		Color = Color3.fromRGB(96, 190, 255),
	},
	Shield = {
		DisplayName = "Shield",
		Duration = 8,
		ShieldHealth = 45,
		Color = Color3.fromRGB(143, 132, 255),
	},
	Nuke = {
		DisplayName = "Nuke",
		Duration = 0,
		NukeDamage = 280,
		Color = Color3.fromRGB(255, 255, 255),
	},
	Freeze = {
		DisplayName = "Freeze",
		Duration = 4,
		FreezeDuration = 4,
		Color = Color3.fromRGB(120, 220, 255),
	},
	Magnet = {
		DisplayName = "Magnet",
		Duration = 10,
		Color = Color3.fromRGB(255, 120, 235),
	},
}

Config.Rarities = {
	Common = {
		DisplayName = "Common",
		Prefix = "",
		Color = Color3.fromRGB(176, 186, 192),
		SizeScale = 1.0,
		GlowRange = 12,
		GlowBrightness = 1.2,
	},
	Rare = {
		DisplayName = "Rare",
		Prefix = "◆ ",
		Color = Color3.fromRGB(72, 162, 255),
		SizeScale = 1.18,
		GlowRange = 17,
		GlowBrightness = 1.7,
	},
	Epic = {
		DisplayName = "Epic",
		Prefix = "★ ",
		Color = Color3.fromRGB(190, 110, 255),
		SizeScale = 1.4,
		GlowRange = 23,
		GlowBrightness = 2.3,
	},
}

Config.Loot = {
	PickupLifetime = 24,
	BaseSize = 3.0,
	DropMargin = 6,
	CoverBuffer = 2.6,
	MagnetRange = 72,
	MagnetSpeed = 50,
	LateWaveDropBonus = 0.04,
	-- Tier-Roll fuer normale Gegner; mit der Welle leicht hochwertiger.
	TierWeights = {
		{Tier = "Common", Weight = 72},
		{Tier = "Rare", Weight = 24},
		{Tier = "Epic", Weight = 4},
	},
	-- Boss garantiert immer Rare oder Epic.
	BossTierWeights = {
		{Tier = "Rare", Weight = 55},
		{Tier = "Epic", Weight = 45},
	},
	Tiers = {
		Common = {
			WeaponChance = 0.28,
			Weapons = {
				{Id = "SMG", Weight = 100},
			},
			Powerups = {
				{Id = "Health", Weight = 60},
				{Id = "SpeedBoost", Weight = 40},
			},
		},
		Rare = {
			WeaponChance = 0.42,
			Weapons = {
				{Id = "Shotgun", Weight = 52},
				{Id = "BurstRifle", Weight = 48},
			},
			Powerups = {
				{Id = "RapidFire", Weight = 30},
				{Id = "DamageBoost", Weight = 28},
				{Id = "Shield", Weight = 22},
				{Id = "Magnet", Weight = 20},
			},
		},
		Epic = {
			WeaponChance = 0.45,
			Weapons = {
				{Id = "Rifle", Weight = 55},
				{Id = "Beam", Weight = 45},
			},
			Powerups = {
				{Id = "Nuke", Weight = 52},
				{Id = "Freeze", Weight = 48},
			},
		},
	},
}

return Config
