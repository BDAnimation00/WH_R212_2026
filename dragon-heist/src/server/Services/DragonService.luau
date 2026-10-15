-- Dragons éclos : affichage sur les socles de la base, revenus en or, revente.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Eggs = require(ReplicatedStorage.Shared.Eggs)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)
local Visuals = require(script.Parent.Visuals)

local DragonService = {}

local states = {} -- [player] = { Pads = { Part }, Visuals = { Model } }

local function sortedChildren(folder)
	local list = folder and folder:GetChildren() or {}
	table.sort(list, function(a, b)
		return (tonumber(string.match(a.Name, "%d+")) or 0) < (tonumber(string.match(b.Name, "%d+")) or 0)
	end)
	return list
end

function DragonService.GetIncome(dragon)
	local egg = Eggs.ById[dragon.EggId]
	local mutation = Config.GetMutation(dragon.Mutation)
	return egg.Income * (if mutation then mutation.Multiplier else 1)
end

function DragonService.GetSellPrice(dragon)
	return math.floor(DragonService.GetIncome(dragon) * Config.SellSeconds)
end

function DragonService.HasRoom(player)
	local state = states[player]
	local data = DataService.Get(player)
	return state ~= nil and data ~= nil and #data.Dragons < #state.Pads
end

local function sell(player, dragon)
	local data = DataService.Get(player)
	local index = data and table.find(data.Dragons, dragon)
	if not index then
		return
	end
	table.remove(data.Dragons, index)
	local price = DragonService.GetSellPrice(dragon)
	DataService.AddGold(player, price)
	Remotes.Notify:FireClient(player, "💰 Dragon vendu pour " .. Format.Number(price) .. " or")
	DragonService.Render(player)
end

function DragonService.Render(player)
	local state = states[player]
	local data = DataService.Get(player)
	if not state or not data then
		return
	end
	for _, visual in state.Visuals do
		visual:Destroy()
	end
	table.clear(state.Visuals)

	local totalIncome = 0
	for i, dragon in data.Dragons do
		local pad = state.Pads[i]
		if not pad then
			break
		end
		local egg = Eggs.ById[dragon.EggId]
		local rarity = Eggs.Rarities[egg.Rarity]
		local mutation = Config.GetMutation(dragon.Mutation)
		local income = DragonService.GetIncome(dragon)
		totalIncome += income

		local visual = Visuals.Dragon(dragon.EggId, dragon.Mutation)
		local _, size = visual:GetBoundingBox()
		visual:PivotTo(pad.CFrame * CFrame.new(0, pad.Size.Y / 2 + size.Y / 2, 0))
		visual.Parent = pad

		local title = Visuals.Colorize(egg.DragonName, rarity.Color)
		if mutation then
			title = Visuals.Colorize(mutation.Name, mutation.Color) .. " " .. title
		end
		local label = Visuals.Label(visual.PrimaryPart, size.Y / 2 + 2, 180)
		label.Text = title .. "\n💰 " .. Format.Number(income) .. "/s"

		local prompt = Visuals.Prompt(visual.PrimaryPart, {
			Name = "SellPrompt",
			ActionText = "Vendre (" .. Format.Number(DragonService.GetSellPrice(dragon)) .. " or)",
			ObjectText = egg.DragonName,
			HoldDuration = 1,
			Audience = "Owner",
			OwnerUserId = player.UserId,
		})
		prompt.Triggered:Connect(function(who)
			if who == player then
				sell(player, dragon)
			end
		end)
		table.insert(state.Visuals, visual)
	end
	player:SetAttribute("IncomePerSecond", totalIncome)
end

function DragonService.Add(player, eggId, mutationName)
	local data = DataService.Get(player)
	if not data then
		return
	end
	table.insert(data.Dragons, { EggId = eggId, Mutation = mutationName })
	DragonService.Render(player)
end

function DragonService.Setup(player, base)
	states[player] = {
		Pads = sortedChildren(base.Model:FindFirstChild("DragonPads")),
		Visuals = {},
	}
	DragonService.Render(player)
end

function DragonService.Cleanup(player)
	local state = states[player]
	if state then
		for _, visual in state.Visuals do
			visual:Destroy()
		end
	end
	states[player] = nil
end

function DragonService.Start()
	-- Revenus : seuls les dragons posés sur un socle rapportent, uniquement quand le joueur est connecté
	task.spawn(function()
		while true do
			task.wait(1)
			for player in states do
				local income = player:GetAttribute("IncomePerSecond") or 0
				if income > 0 then
					DataService.AddGold(player, income)
				end
			end
		end
	end)
end

return DragonService
