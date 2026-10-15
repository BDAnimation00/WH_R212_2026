-- Nids : toutes les 5 minutes, chaque zone se remplit de nouveaux œufs (pour tout le serveur).
-- La nuit, les œufs rares apparaissent plus souvent. Les œufs très rares sont annoncés à tout le monde.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Eggs = require(ReplicatedStorage.Shared.Eggs)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CharacterService = require(script.Parent.CharacterService)
local DayNightService = require(script.Parent.DayNightService)
local Visuals = require(script.Parent.Visuals)

local EggSpawnService = {}

local rng = Random.new()
local container

-- Point au hasard sur une zone : sur l'anneau (attributs InnerRadius / OuterRadius) ou sur toute la pièce.
-- L'œuf se pose ensuite sur ce qui est en dessous dans NestZones (relief compris).
local function randomPointOn(zonePart, zonesFolder)
	local x, z
	local inner = zonePart:GetAttribute("InnerRadius")
	local outer = zonePart:GetAttribute("OuterRadius")
	if inner and outer then
		local margin = 4
		local r = math.sqrt(rng:NextNumber() * ((outer - margin) ^ 2 - (inner + margin) ^ 2) + (inner + margin) ^ 2)
		local angle = rng:NextNumber() * math.pi * 2
		x = zonePart.Position.X + math.cos(angle) * r
		z = zonePart.Position.Z + math.sin(angle) * r
	else
		local size = zonePart.Size
		local point = zonePart.CFrame * CFrame.new((rng:NextNumber() - 0.5) * size.X * 0.9, 0, (rng:NextNumber() - 0.5) * size.Z * 0.9)
		x, z = point.Position.X, point.Position.Z
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { zonesFolder }
	local origin = Vector3.new(x, zonePart.Position.Y + 300, z)
	local hit = workspace:Raycast(origin, Vector3.new(0, -600, 0), params)
	local y = if hit then hit.Position.Y else zonePart.Position.Y + zonePart.Size.Y / 2
	return CFrame.new(x, y + 1.4, z)
end

local function spawnEgg(zonePart, zonesFolder, egg)
	local visual = Visuals.Egg(egg.Id, true)
	visual:PivotTo(randomPointOn(zonePart, zonesFolder))
	visual.Parent = container

	local rarity = Eggs.Rarities[egg.Rarity]
	local label = Visuals.Label(visual.PrimaryPart, 3, 160)
	label.Text = Visuals.Colorize(egg.EggName, rarity.Color) .. "\n" .. Visuals.Colorize(rarity.Label, rarity.Color)
	label.Parent.MaxDistance = 60

	local prompt = Visuals.Prompt(visual.PrimaryPart, {
		Name = "TakePrompt",
		ActionText = "Prendre",
		ObjectText = egg.EggName,
		HoldDuration = 0.3,
		Audience = "All",
	})
	prompt.Triggered:Connect(function(player)
		if not visual.Parent then
			return
		end
		if CharacterService.GetCarried(player) then
			Remotes.Notify:FireClient(player, "🥚 Tu portes déjà un œuf ! Pose-le dans un incubateur.")
			return
		end
		if CharacterService.StartCarry(player, egg.Id, 0) then
			visual:Destroy()
		end
	end)
end

local function refill()
	container:ClearAllChildren()
	local isNight = DayNightService.IsNight()
	local zones = workspace.Map:FindFirstChild("NestZones")
	if not zones then
		warn("[EggSpawnService] Aucun dossier Map/NestZones")
		return
	end
	-- Regroupe les pièces par zone (une zone peut être faite de plusieurs pièces)
	local partsByZone = {}
	for _, zonePart in zones:GetChildren() do
		local zone = zonePart:GetAttribute("Zone")
		if zonePart:IsA("BasePart") and zone then
			partsByZone[zone] = partsByZone[zone] or {}
			table.insert(partsByZone[zone], zonePart)
		end
	end

	for zone, parts in partsByZone do
		for _ = 1, Config.EggsPerZone[zone] or 6 do
			local egg = Eggs.Roll(zone, isNight, Config.NightRareBoost, rng)
			if egg then
				spawnEgg(parts[rng:NextInteger(1, #parts)], zones, egg)
				local rarity = Eggs.Rarities[egg.Rarity]
				if rarity.Order >= Config.AnnounceRarityOrder then
					Remotes.Notify:FireAllClients(string.format(
						"📢 Un œuf %s est apparu : %s (%s) !",
						string.upper(rarity.Label),
						egg.EggName,
						Eggs.Zones[zone] or "?"
					))
				end
			end
		end
	end
	Remotes.Notify:FireAllClients("🥚 Les nids se sont remplis !")
end

function EggSpawnService.Start()
	container = Instance.new("Folder")
	container.Name = "WildEggs"
	container.Parent = workspace

	task.spawn(function()
		while true do
			refill()
			ReplicatedStorage:SetAttribute("EggRespawnAt", workspace:GetServerTimeNow() + Config.EggRespawnInterval)
			task.wait(Config.EggRespawnInterval)
		end
	end)
end

return EggSpawnService
