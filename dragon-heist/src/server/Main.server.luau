-- Point d'entrée du serveur : démarre tous les systèmes et gère l'arrivée / le départ des joueurs.

local Players = game:GetService("Players")

local WorldBuilder = require(script.Parent.WorldBuilder)
if not workspace:FindFirstChild("Map") then
	WorldBuilder.Build().Parent = workspace
end

local Services = script.Parent.Services
local BaseService = require(Services.BaseService)
local CharacterService = require(Services.CharacterService)
local DataService = require(Services.DataService)
local DayNightService = require(Services.DayNightService)
local DragonService = require(Services.DragonService)
local EggSpawnService = require(Services.EggSpawnService)
local IncubatorService = require(Services.IncubatorService)
local ShopService = require(Services.ShopService)

DataService.Start()
DayNightService.Start()
BaseService.Start()
DragonService.Start()
IncubatorService.Start()
EggSpawnService.Start()
ShopService.Start()

local function onPlayerAdded(player)
	DataService.Load(player)
	if not player.Parent then
		DataService.Release(player)
		return
	end
	local base = BaseService.Assign(player)
	if not base then
		player:Kick("Serveur plein, réessaie sur un autre serveur !")
		return
	end
	DragonService.Setup(player, base)
	IncubatorService.Setup(player, base)
	CharacterService.Setup(player)
end

local function onPlayerRemoving(player)
	IncubatorService.Cleanup(player)
	DragonService.Cleanup(player)
	CharacterService.Cleanup(player)
	BaseService.Release(player)
	DataService.Release(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
