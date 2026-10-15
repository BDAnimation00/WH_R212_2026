-- MAP DE BASE (placeholder)
-- Construit la carte de départ : 8 bases + 3 zones de nids (Forêt, Volcan, Ciel).
-- Le fichier DragonHeist.rbxlx contient déjà cette map : tu peux la modifier librement dans Studio.
-- Ce script ne la reconstruit QUE si workspace.Map n'existe pas.
--
-- Noms importants à garder si tu remplaces les pièces par tes modèles :
--   Map/Bases/Base_1..8   : Floor, Door, LockButton, Spawn, Sign,
--                           Incubators/Incubator_1..6, DragonPads/Pad_1..8
--   Map/NestZones/*       : pièces avec l'attribut "Zone" (1, 2 ou 3) ; les œufs apparaissent dessus

local WorldBuilder = {}

local BASE_COUNT = 8
local INCUBATORS = 6
local PADS = 8

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		p[key] = value
	end
	return p
end

local function sign(parent, text, offsetY, color)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.new(0, 260, 0, 60)
	gui.StudsOffset = Vector3.new(0, offsetY, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 400
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.2
	label.Text = text
	label.Parent = gui
	gui.Parent = parent
	return gui
end

local function buildBase(index, cf)
	local model = Instance.new("Model")
	model.Name = "Base_" .. index

	local function at(x, y, z)
		return cf * CFrame.new(x, y, z)
	end

	local floor = part({
		Name = "Floor",
		Size = Vector3.new(44, 1, 44),
		CFrame = at(0, 0.5, 0),
		Color = Color3.fromRGB(120, 105, 90),
		Material = Enum.Material.WoodPlanks,
		Parent = model,
	})
	model.PrimaryPart = floor

	local wallColor = Color3.fromRGB(150, 140, 125)
	part({ Name = "WallBack", Size = Vector3.new(44, 12, 1), CFrame = at(0, 7, 22), Color = wallColor, Material = Enum.Material.Brick, Parent = model })
	part({ Name = "WallLeft", Size = Vector3.new(1, 12, 44), CFrame = at(-22, 7, 0), Color = wallColor, Material = Enum.Material.Brick, Parent = model })
	part({ Name = "WallRight", Size = Vector3.new(1, 12, 44), CFrame = at(22, 7, 0), Color = wallColor, Material = Enum.Material.Brick, Parent = model })

	-- Porte (avant de la base, face au centre de la map). Transparente quand elle est ouverte.
	part({
		Name = "Door",
		Size = Vector3.new(42, 12, 1),
		CFrame = at(0, 7, -22),
		Color = Color3.fromRGB(80, 220, 120),
		Material = Enum.Material.ForceField,
		Transparency = 0.85,
		CanCollide = false,
		Parent = model,
	})

	part({
		Name = "LockButton",
		Size = Vector3.new(3, 2, 3),
		CFrame = at(17, 2, -17),
		Color = Color3.fromRGB(230, 60, 60),
		Material = Enum.Material.Neon,
		Parent = model,
	})

	part({
		Name = "Spawn",
		Size = Vector3.new(6, 0.2, 6),
		CFrame = at(0, 1.1, 6),
		Color = Color3.fromRGB(255, 255, 255),
		Material = Enum.Material.SmoothPlastic,
		Transparency = 0.5,
		CanCollide = false,
		Parent = model,
	})

	local signPart = part({
		Name = "Sign",
		Size = Vector3.new(1, 1, 1),
		CFrame = at(0, 16, 0),
		Transparency = 1,
		CanCollide = false,
		Parent = model,
	})
	sign(signPart, "Base libre", 0, Color3.fromRGB(255, 255, 255))

	local incubators = Instance.new("Folder")
	incubators.Name = "Incubators"
	incubators.Parent = model
	for i = 1, INCUBATORS do
		part({
			Name = "Incubator_" .. i,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.5, 5, 5),
			CFrame = at(-15 + (i - 1) * 6, 1.75, -8) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(240, 190, 90),
			Material = Enum.Material.SmoothPlastic,
			Parent = incubators,
		})
	end

	local pads = Instance.new("Folder")
	pads.Name = "DragonPads"
	pads.Parent = model
	for i = 1, PADS do
		part({
			Name = "Pad_" .. i,
			Size = Vector3.new(4.5, 0.4, 4.5),
			CFrame = at(-17.5 + (i - 1) * 5, 1.2, 15),
			Color = Color3.fromRGB(90, 90, 110),
			Material = Enum.Material.Slate,
			Parent = pads,
		})
	end

	return model
end

local function tree(parent, position)
	part({
		Name = "Trunk",
		Size = Vector3.new(2, 10, 2),
		CFrame = CFrame.new(position + Vector3.new(0, 5, 0)),
		Color = Color3.fromRGB(105, 70, 40),
		Material = Enum.Material.Wood,
		Parent = parent,
	})
	part({
		Name = "Leaves",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(9, 9, 9),
		CFrame = CFrame.new(position + Vector3.new(0, 12, 0)),
		Color = Color3.fromRGB(60, 140, 60),
		Material = Enum.Material.Grass,
		Parent = parent,
	})
end

function WorldBuilder.Build()
	local map = Instance.new("Folder")
	map.Name = "Map"

	part({
		Name = "Ground",
		Size = Vector3.new(500, 2, 800),
		CFrame = CFrame.new(0, -1, -220),
		Color = Color3.fromRGB(110, 170, 90),
		Material = Enum.Material.Grass,
		Parent = map,
	})

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = CFrame.new(0, 0.5, 90)
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = map

	-- Bases : 4 à gauche, 4 à droite, portes tournées vers le centre
	local bases = Instance.new("Folder")
	bases.Name = "Bases"
	bases.Parent = map
	local rowsZ = { 60, 0, -60, -120 }
	for i = 1, BASE_COUNT do
		local side = if i <= 4 then -1 else 1
		local z = rowsZ[(i - 1) % 4 + 1]
		local position = Vector3.new(110 * side, 0, z)
		-- La porte est à l'avant (-Z local), on oriente donc l'avant vers le centre (x = 0)
		local cf = CFrame.lookAt(position, position + Vector3.new(-side, 0, 0))
		buildBase(i, cf).Parent = bases
	end

	-- Zones de nids : plus c'est loin, plus c'est rare
	local zones = Instance.new("Folder")
	zones.Name = "NestZones"
	zones.Parent = map

	local forest = part({
		Name = "Foret",
		Size = Vector3.new(120, 0.2, 200),
		CFrame = CFrame.new(0, 0.1, -30),
		Color = Color3.fromRGB(70, 130, 60),
		Material = Enum.Material.LeafyGrass,
		Parent = zones,
	})
	forest:SetAttribute("Zone", 1)
	sign(forest, "🌲 FORÊT", 14, Color3.fromRGB(150, 255, 150))

	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = map
	for _, offset in { Vector3.new(-50, 0, 40), Vector3.new(50, 0, 10), Vector3.new(-45, 0, -90), Vector3.new(48, 0, -110) } do
		tree(decor, Vector3.new(offset.X, 0.2, offset.Z))
	end

	local volcano = part({
		Name = "Volcan",
		Size = Vector3.new(140, 0.2, 140),
		CFrame = CFrame.new(0, 0.1, -300),
		Color = Color3.fromRGB(70, 40, 35),
		Material = Enum.Material.CrackedLava,
		Parent = zones,
	})
	volcano:SetAttribute("Zone", 2)
	sign(volcano, "🌋 VOLCAN", 14, Color3.fromRGB(255, 140, 60))

	-- Rampe vers le Ciel : monte de y=0 (z=-375) à y=40 (z=-465)
	local rise, run = 40, 90
	part({
		Name = "SkyRamp",
		Size = Vector3.new(20, 1, math.sqrt(rise * rise + run * run)),
		CFrame = CFrame.new(0, rise / 2, -375 - run / 2) * CFrame.Angles(math.atan2(rise, run), 0, 0),
		Color = Color3.fromRGB(230, 230, 255),
		Material = Enum.Material.Marble,
		Parent = map,
	})

	local sky = part({
		Name = "Ciel",
		Size = Vector3.new(130, 1, 130),
		CFrame = CFrame.new(0, 40, -530),
		Color = Color3.fromRGB(235, 245, 255),
		Material = Enum.Material.Glacier,
		Parent = zones,
	})
	sky:SetAttribute("Zone", 3)
	sign(sky, "☁️ CIEL", 14, Color3.fromRGB(150, 230, 255))

	return map
end

return WorldBuilder
