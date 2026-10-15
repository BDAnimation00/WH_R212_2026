-- Incubateurs : poser un œuf, éclosion en temps réel (accélérée si connecté, x10 la nuit),
-- faire éclore (tirage des mutations), vol par les autres joueurs, achat d'incubateurs.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Eggs = require(ReplicatedStorage.Shared.Eggs)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local BaseService = require(script.Parent.BaseService)
local CharacterService = require(script.Parent.CharacterService)
local DataService = require(script.Parent.DataService)
local DayNightService = require(script.Parent.DayNightService)
local DragonService = require(script.Parent.DragonService)
local Visuals = require(script.Parent.Visuals)

local IncubatorService = {}

local states = {} -- [player] = { Base, Slots = { [i] = slot } }
local rng = Random.new()

local function sortedChildren(folder)
	local list = folder and folder:GetChildren() or {}
	table.sort(list, function(a, b)
		return (tonumber(string.match(a.Name, "%d+")) or 0) < (tonumber(string.match(b.Name, "%d+")) or 0)
	end)
	return list
end

local function setActive(prompt, active)
	prompt:SetAttribute("Active", active)
end

local function rollMutation(isNight)
	if isNight and rng:NextNumber() < Config.NightMutation.Chance then
		return Config.NightMutation.Name
	end
	local roll = rng:NextNumber()
	for _, mutation in Config.Mutations do
		if roll < mutation.Chance then
			return mutation.Name
		end
		roll -= mutation.Chance
	end
	return nil
end

local function updateLabel(player, index)
	local state = states[player]
	local data = DataService.Get(player)
	local slot = state and state.Slots[index]
	if not slot or not data then
		return
	end

	if index > data.IncubatorCount then
		if index == data.IncubatorCount + 1 then
			slot.Label.Text = "🔒 Incubateur\n💰 " .. Format.Number(Config.IncubatorCost(data.IncubatorCount))
		else
			slot.Label.Text = "🔒"
		end
		return
	end

	local entry = data.Incubators[tostring(index)]
	if not entry then
		slot.Label.Text = "Vide\n<font size=\"14\">Pose un œuf ici</font>"
		return
	end

	local egg = Eggs.ById[entry.EggId]
	local rarity = Eggs.Rarities[egg.Rarity]
	local title = Visuals.Colorize(egg.EggName, rarity.Color)
	if entry.Progress >= egg.HatchTime then
		slot.Label.Text = title .. "\n✨ PRÊT À ÉCLORE !"
	else
		local rate = DayNightService.GetHatchRate()
		local remaining = (egg.HatchTime - entry.Progress) / rate
		local speed = if DayNightService.IsNight() then " 🌙x" .. rate else ""
		slot.Label.Text = title .. "\n⏳ " .. Format.Time(remaining) .. speed
	end
end

function IncubatorService.Render(player, index)
	local state = states[player]
	local data = DataService.Get(player)
	local slot = state and state.Slots[index]
	if not slot or not data then
		return
	end

	local owned = index <= data.IncubatorCount
	local entry = owned and data.Incubators[tostring(index)] or nil
	local eggId = entry and entry.EggId or nil

	slot.Part.Transparency = if owned then 0 else 0.6

	-- Visuel de l'œuf posé
	if slot.VisualEggId ~= eggId then
		if slot.Visual then
			slot.Visual:Destroy()
			slot.Visual = nil
		end
		if eggId then
			local visual = Visuals.Egg(eggId, true)
			visual:PivotTo(slot.Part.CFrame * CFrame.Angles(0, 0, math.rad(-90)) * CFrame.new(0, 2.2, 0))
			visual.Parent = slot.Part
			slot.Visual = visual
		end
		slot.VisualEggId = eggId
	end

	local ready = entry ~= nil and entry.Progress >= Eggs.ById[entry.EggId].HatchTime
	setActive(slot.BuyPrompt, index == data.IncubatorCount + 1 and index <= Config.MaxIncubators)
	slot.BuyPrompt.ActionText = "Acheter (" .. Format.Number(Config.IncubatorCost(data.IncubatorCount)) .. " or)"
	setActive(slot.PlacePrompt, owned and entry == nil)
	setActive(slot.HatchPrompt, ready)
	setActive(slot.StealPrompt, entry ~= nil)
	slot.StealPrompt.ObjectText = if entry then Eggs.ById[entry.EggId].EggName else ""
	updateLabel(player, index)
end

local function renderAll(player)
	local state = states[player]
	if state then
		for index in state.Slots do
			IncubatorService.Render(player, index)
		end
	end
end

local function onPlace(owner, index, who)
	if who ~= owner then
		return
	end
	local data = DataService.Get(owner)
	if not data or index > data.IncubatorCount or data.Incubators[tostring(index)] then
		return
	end
	local carried = CharacterService.GetCarried(owner)
	if not carried then
		Remotes.Notify:FireClient(owner, "🥚 Va chercher un œuf dans les nids d'abord !")
		return
	end
	CharacterService.StopCarry(owner)
	data.Incubators[tostring(index)] = { EggId = carried.EggId, Progress = carried.Progress }
	IncubatorService.Render(owner, index)
end

local function onHatch(owner, index, who)
	if who ~= owner then
		return
	end
	local data = DataService.Get(owner)
	local entry = data and data.Incubators[tostring(index)]
	if not entry then
		return
	end
	local egg = Eggs.ById[entry.EggId]
	if entry.Progress < egg.HatchTime then
		return
	end
	if not DragonService.HasRoom(owner) then
		Remotes.Notify:FireClient(owner, "🐉 Plus de place sur tes socles : vends un dragon d'abord !")
		return
	end
	data.Incubators[tostring(index)] = nil
	local mutation = rollMutation(DayNightService.IsNight())
	DragonService.Add(owner, egg.Id, mutation)
	Remotes.HatchReveal:FireClient(owner, egg.Id, mutation)
	IncubatorService.Render(owner, index)
end

local function onSteal(owner, index, thief)
	if thief == owner or not BaseService.GetBase(thief) then
		return
	end
	local base = states[owner] and states[owner].Base
	if not base or BaseService.IsLocked(base) then
		Remotes.Notify:FireClient(thief, "🔒 Cette base est verrouillée !")
		return
	end
	if CharacterService.GetCarried(thief) then
		Remotes.Notify:FireClient(thief, "🥚 Tu portes déjà un œuf !")
		return
	end
	local data = DataService.Get(owner)
	local entry = data and data.Incubators[tostring(index)]
	if not entry then
		return
	end
	if not CharacterService.StartCarry(thief, entry.EggId, entry.Progress) then
		return
	end
	data.Incubators[tostring(index)] = nil
	IncubatorService.Render(owner, index)

	local eggName = Eggs.ById[entry.EggId].EggName
	Remotes.Notify:FireClient(owner, "🚨 " .. thief.DisplayName .. " t'a volé ton " .. eggName .. " !")
	Remotes.Notify:FireClient(thief, "😈 Tu as volé un " .. eggName .. " ! Ramène-le vite à ta base !")
end

local function onBuy(owner, index, who)
	if who ~= owner then
		return
	end
	local data = DataService.Get(owner)
	if not data or index ~= data.IncubatorCount + 1 or index > Config.MaxIncubators then
		return
	end
	local cost = Config.IncubatorCost(data.IncubatorCount)
	if not DataService.SpendGold(owner, cost) then
		Remotes.Notify:FireClient(owner, "💰 Il te faut " .. Format.Number(cost) .. " or.")
		return
	end
	data.IncubatorCount += 1
	DataService.Sync(owner)
	Remotes.Notify:FireClient(owner, "✅ Nouvel incubateur débloqué !")
	renderAll(owner)
end

function IncubatorService.Setup(player, base)
	local state = { Base = base, Slots = {} }
	states[player] = state

	local parts = sortedChildren(base.Model:FindFirstChild("Incubators"))
	for index, part in parts do
		if index > Config.MaxIncubators then
			break
		end
		local userId = player.UserId
		local slot = { Part = part }
		slot.Label = Visuals.Label(part, 5, 200)
		slot.PlacePrompt = Visuals.Prompt(part, { Name = "PlacePrompt", ActionText = "Poser l'œuf", Audience = "Owner", OwnerUserId = userId })
		slot.HatchPrompt = Visuals.Prompt(part, { Name = "HatchPrompt", ActionText = "Faire éclore !", Audience = "Owner", OwnerUserId = userId, Key = Enum.KeyCode.F })
		slot.StealPrompt = Visuals.Prompt(part, {
			Name = "StealPrompt",
			ActionText = "Voler",
			HoldDuration = Config.StealHoldDuration,
			Audience = "Others",
			OwnerUserId = userId,
		})
		slot.BuyPrompt = Visuals.Prompt(part, { Name = "BuyPrompt", ActionText = "Acheter", ObjectText = "Incubateur", Audience = "Owner", OwnerUserId = userId })

		slot.PlacePrompt.Triggered:Connect(function(who)
			onPlace(player, index, who)
		end)
		slot.HatchPrompt.Triggered:Connect(function(who)
			onHatch(player, index, who)
		end)
		slot.StealPrompt.Triggered:Connect(function(who)
			onSteal(player, index, who)
		end)
		slot.BuyPrompt.Triggered:Connect(function(who)
			onBuy(player, index, who)
		end)
		state.Slots[index] = slot
	end
	renderAll(player)
end

function IncubatorService.Cleanup(player)
	local state = states[player]
	if not state then
		return
	end
	for _, slot in state.Slots do
		slot.Part.Transparency = 0
		if slot.Visual then
			slot.Visual:Destroy()
		end
		slot.Label.Parent:Destroy()
		for _, prompt in { slot.PlacePrompt, slot.HatchPrompt, slot.StealPrompt, slot.BuyPrompt } do
			prompt:Destroy()
		end
	end
	states[player] = nil
end

function IncubatorService.Start()
	-- Éclosion : chaque seconde, les œufs des joueurs connectés avancent (x2 de jour, x10 la nuit par défaut)
	task.spawn(function()
		local last = os.clock()
		while true do
			task.wait(1)
			local now = os.clock()
			local dt = now - last
			last = now
			local rate = DayNightService.GetHatchRate()
			for player, state in states do
				local data = DataService.Get(player)
				if data then
					for key, entry in data.Incubators do
						local egg = Eggs.ById[entry.EggId]
						if entry.Progress < egg.HatchTime then
							entry.Progress = math.min(egg.HatchTime, entry.Progress + dt * rate)
							if entry.Progress >= egg.HatchTime then
								Remotes.Notify:FireClient(player, "✨ Ton " .. egg.EggName .. " est prêt à éclore !")
								IncubatorService.Render(player, tonumber(key))
							end
						end
					end
					for index in state.Slots do
						updateLabel(player, index)
					end
				end
			end
		end
	end)
end

return IncubatorService
