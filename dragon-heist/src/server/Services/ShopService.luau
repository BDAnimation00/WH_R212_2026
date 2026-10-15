-- Boutique : amélioration de vitesse (payée en or).
-- Plus tard : game passes et produits Robux (vitesse x2, chance, œufs premium...).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CharacterService = require(script.Parent.CharacterService)
local DataService = require(script.Parent.DataService)

local ShopService = {}

local lastRequest = {}

local function onUpgradeSpeed(player)
	local now = os.clock()
	if lastRequest[player] and now - lastRequest[player] < 0.2 then
		return
	end
	lastRequest[player] = now

	local data = DataService.Get(player)
	if not data then
		return
	end
	if data.SpeedLevel >= Config.MaxSpeedLevel then
		Remotes.Notify:FireClient(player, "⚡ Vitesse au maximum !")
		return
	end
	local cost = Config.SpeedCost(data.SpeedLevel)
	if not DataService.SpendGold(player, cost) then
		Remotes.Notify:FireClient(player, "💰 Il te faut " .. Format.Number(cost) .. " or.")
		return
	end
	data.SpeedLevel += 1
	DataService.Sync(player)
	CharacterService.Refresh(player)
end

function ShopService.Start()
	Remotes.UpgradeSpeed.OnServerEvent:Connect(onUpgradeSpeed)
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
	end)
end

return ShopService
