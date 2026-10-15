-- Boutique au centre de la map : amélioration de vitesse (payée en or).
-- On ne peut acheter qu'à côté du comptoir : tout le monde repasse par le centre.
-- Plus tard : game passes et produits Robux (vitesse x2, chance, œufs premium...).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CharacterService = require(script.Parent.CharacterService)
local DataService = require(script.Parent.DataService)
local Visuals = require(script.Parent.Visuals)

local ShopService = {}

local lastRequest = {}
local counter = nil

local function isNearShop(player)
	if not counter then
		return true
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return root ~= nil and (root.Position - counter.Position).Magnitude <= Config.ShopRange
end

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
	if not isNearShop(player) then
		Remotes.Notify:FireClient(player, "🛒 Va à la boutique au centre de la map pour acheter !")
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
	local shop = workspace.Map:FindFirstChild("Shop")
	counter = shop and shop:FindFirstChild("ShopCounter", true)
	if counter then
		local prompt = Visuals.Prompt(counter, {
			Name = "ShopPrompt",
			ActionText = "Ouvrir",
			ObjectText = "Boutique",
			Audience = "All",
			Distance = 14,
		})
		prompt.Triggered:Connect(function(player)
			Remotes.OpenShop:FireClient(player, counter.Position)
		end)
	else
		warn("[ShopService] Aucun Map/Shop/ShopCounter : la boutique est accessible partout")
	end

	Remotes.UpgradeSpeed.OnServerEvent:Connect(onUpgradeSpeed)
	Players.PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
	end)
end

return ShopService
