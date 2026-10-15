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

local function randomPointOn(zonePart)
	local size = zonePart.Size
	local x = (rng:NextNumber() - 0.5) * size.X * 0.9
	local z = (rng:NextNumber() - 0.5) * size.Z * 0.9
	return zonePart.CFrame * CFrame.new(x, size.Y / 2 + 1.4, z)
end

local function spawnEgg(zonePart, egg)
	local visual = Visuals.Egg(egg.Id, true)
	local cf = randomPointOn(zonePart)
	visual:PivotTo(CFrame.new(cf.Position))
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
	for _, zonePart in zones:GetChildren() do
		local zone = zonePart:GetAttribute("Zone")
		if zonePart:IsA("BasePart") and zone then
			for _ = 1, Config.EggsPerNest do
				local egg = Eggs.Roll(zone, isNight, Config.NightRareBoost, rng)
				if egg then
					spawnEgg(zonePart, egg)
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
