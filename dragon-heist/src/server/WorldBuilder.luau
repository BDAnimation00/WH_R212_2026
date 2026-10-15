-- MAP DE BASE (placeholder) — disposition en cercle
--   Centre : la boutique
--   Autour : les 8 bases, en cercle, portes tournées vers le centre
--   Puis des anneaux de nids : Forêt → Volcan → Ciel (plus on s'éloigne, plus c'est rare)
--
-- Le fichier DragonHeist.rbxlx contient déjà cette map : tu peux la modifier librement dans Studio.
-- Ce script ne la reconstruit QUE si workspace.Map n'existe pas.
--
-- Noms importants à garder si tu remplaces les pièces par tes modèles :
--   Map/Shop/ShopCounter  : comptoir de la boutique (le prompt "Boutique" s'y attache)
--   Map/Bases/Base_1..8   : Floor, Door, LockButton, Spawn, Sign,
--                           Incubators/Incubator_1..6, DragonPads/Pad_1..8
--   Map/NestZones/*       : pièces avec l'attribut "Zone" (1, 2 ou 3).
--                           Avec les attributs InnerRadius / OuterRadius, les œufs apparaissent sur l'anneau.
--                           Les œufs se posent sur le décor qui est en dessous (tu peux ajouter du relief).

local WorldBuilder = {}

local BASE_COUNT = 8
local BASE_RING_RADIUS = 90
local INCUBATORS = 6
local PADS = 8

-- Rayons des anneaux (en studs, depuis le centre)
local PLAZA_RADIUS = 125
local RINGS = {
	{ Name = "Foret", Label = "🌲 FORÊT", Zone = 1, Inner = PLAZA_RADIUS, Outer = 190, Color = Color3.fromRGB(70, 130, 60), Material = Enum.Material.LeafyGrass, TextColor = Color3.fromRGB(150, 255, 150) },
	{ Name = "Volcan", Label = "🌋 VOLCAN", Zone = 2, Inner = 190, Outer = 265, Color = Color3.fromRGB(70, 40, 35), Material = Enum.Material.CrackedLava, TextColor = Color3.fromRGB(255, 140, 60) },
	{ Name = "Ciel", Label = "☁️ CIEL", Zone = 3, Inner = 265, Outer = 340, Color = Color3.fromRGB(225, 238, 255), Material = Enum.Material.Glacier, TextColor = Color3.fromRGB(150, 230, 255) },
}

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

-- Disque plat de rayon `radius` dont le dessus est à la hauteur `top`
local function disc(name, radius, top, color, material, parent)
	return part({
		Name = name,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1, radius * 2, radius * 2),
		CFrame = CFrame.new(0, top - 0.5, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = color,
		Material = material,
		Parent = parent,
	})
end

local function sign(parent, text, offsetY, color)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.new(0, 260, 0, 60)
	gui.StudsOffset = Vector3.new(0, offsetY, 0)
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

local function marker(parent, name, position)
	return part({
		Name = name,
		Size = Vector3.new(1, 1, 1),
		CFrame = CFrame.new(position),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		Parent = parent,
	})
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

	-- Porte à l'avant (-Z local). Transparente quand elle est ouverte.
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

	local signPart = marker(model, "Sign", at(0, 16, 0).Position)
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

local function buildShop(parent)
	local shop = Instance.new("Model")
	shop.Name = "Shop"

	local floor = part({
		Name = "ShopFloor",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1, 36, 36),
		CFrame = CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(230, 200, 140),
		Material = Enum.Material.Sandstone,
		Parent = shop,
	})
	shop.PrimaryPart = floor

	part({
		Name = "ShopCounter",
		Size = Vector3.new(14, 4, 6),
		CFrame = CFrame.new(0, 3, 0),
		Color = Color3.fromRGB(150, 95, 55),
		Material = Enum.Material.Wood,
		Parent = shop,
	})
	for _, corner in { Vector3.new(-8, 0, -8), Vector3.new(8, 0, -8), Vector3.new(-8, 0, 8), Vector3.new(8, 0, 8) } do
		part({
			Name = "Pillar",
			Size = Vector3.new(1.5, 14, 1.5),
			CFrame = CFrame.new(corner + Vector3.new(0, 8, 0)),
			Color = Color3.fromRGB(240, 240, 240),
			Material = Enum.Material.Marble,
			Parent = shop,
		})
	end
	local roof = part({
		Name = "Roof",
		Size = Vector3.new(22, 1.5, 22),
		CFrame = CFrame.new(0, 15.5, 0),
		Color = Color3.fromRGB(220, 60, 60),
		Material = Enum.Material.SmoothPlastic,
		Parent = shop,
	})
	sign(roof, "🛒 BOUTIQUE", 6, Color3.fromRGB(255, 220, 90))

	shop.Parent = parent
	return shop
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

local function rock(parent, position, color)
	part({
		Name = "Rock",
		Size = Vector3.new(7, 5, 6),
		CFrame = CFrame.new(position + Vector3.new(0, 2, 0)) * CFrame.Angles(0.3, position.X % 3, 0.2),
		Color = color,
		Material = Enum.Material.Basalt,
		Parent = parent,
	})
end

local function polar(radius, angle, y)
	return Vector3.new(math.cos(angle) * radius, y or 0, math.sin(angle) * radius)
end

function WorldBuilder.Build()
	local map = Instance.new("Folder")
	map.Name = "Map"

	-- Sol extérieur (évite de tomber dans le vide au bord de la map)
	part({
		Name = "Ground",
		Size = Vector3.new(900, 2, 900),
		CFrame = CFrame.new(0, -1.2, 0),
		Color = Color3.fromRGB(110, 170, 90),
		Material = Enum.Material.Grass,
		Parent = map,
	})

	-- Anneaux de nids : disques empilés, du plus grand (Ciel) au plus petit (place centrale)
	local zones = Instance.new("Folder")
	zones.Name = "NestZones"
	zones.Parent = map
	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = map

	for i = #RINGS, 1, -1 do
		local ring = RINGS[i]
		local zonePart = disc(ring.Name, ring.Outer, 0.2 * (#RINGS - i), ring.Color, ring.Material, zones)
		zonePart:SetAttribute("Zone", ring.Zone)
		zonePart:SetAttribute("InnerRadius", ring.Inner)
		zonePart:SetAttribute("OuterRadius", ring.Outer)

		-- Panneaux du nom de zone, aux 4 coins de l'anneau
		local middle = (ring.Inner + ring.Outer) / 2
		for k = 0, 3 do
			local anchor = marker(decor, "ZoneSign_" .. ring.Name, polar(middle, math.rad(45 + k * 90), 2))
			sign(anchor, ring.Label, 12, ring.TextColor)
		end
	end

	disc("Plaza", PLAZA_RADIUS, 0.2 * #RINGS, Color3.fromRGB(205, 195, 175), Enum.Material.Cobblestone, map)
	local plazaTop = 0.2 * #RINGS

	-- Décor : arbres dans la Forêt, rochers dans le Volcan
	for k = 0, 11 do
		local angle = math.rad(k * 30 + 15)
		tree(decor, polar(150 + (k % 3) * 12, angle, 0.4))
	end
	for k = 0, 9 do
		local angle = math.rad(k * 36 + 5)
		rock(decor, polar(215 + (k % 2) * 25, angle, 0.2), Color3.fromRGB(45, 35, 35))
	end

	-- Boutique au centre + point d'apparition à côté
	buildShop(map)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(0, plazaTop + 0.5, 26)
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = map

	-- Bases en cercle autour de la boutique, porte tournée vers le centre
	local bases = Instance.new("Folder")
	bases.Name = "Bases"
	bases.Parent = map
	for i = 1, BASE_COUNT do
		local angle = math.rad((i - 1) * (360 / BASE_COUNT))
		local position = polar(BASE_RING_RADIUS, angle, plazaTop)
		-- Rotation qui tourne l'avant de la base (-Z local, la porte) vers le centre (la boutique)
		local cf = CFrame.new(position) * CFrame.Angles(0, math.pi / 2 - angle, 0)
		buildBase(i, cf).Parent = bases
	end

	return map
end

return WorldBuilder
