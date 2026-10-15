-- Sauvegarde et chargement de la progression des joueurs (DataStore).
-- Dans Studio : Paramètres du jeu > Sécurité > "Enable Studio Access to API Services" pour tester la sauvegarde.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Eggs = require(ReplicatedStorage.Shared.Eggs)
local Format = require(ReplicatedStorage.Shared.Format)

local DataService = {}

local profiles = {} -- [player] = { Data = table, CanSave = bool }

local store = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStoreName)
	end)
	if ok then
		store = result
	else
		warn("[DataService] DataStore indisponible :", result)
	end
end

local function defaultData()
	return {
		Gold = Config.StartGold,
		SpeedLevel = 0,
		IncubatorCount = Config.StartIncubators,
		Incubators = {}, -- ["1"] = { EggId = "Ember", Progress = 0 }
		Dragons = {}, -- { { EggId = "Ember", Mutation = "Doré" | nil } }
		LastOnline = os.time(),
	}
end

local function reconcile(data)
	for key, value in defaultData() do
		if data[key] == nil then
			data[key] = value
		end
	end
	-- Retire les œufs / dragons qui n'existent plus dans Eggs.luau
	for slot, entry in data.Incubators do
		if not Eggs.ById[entry.EggId] then
			data.Incubators[slot] = nil
		end
	end
	for i = #data.Dragons, 1, -1 do
		if not Eggs.ById[data.Dragons[i].EggId] then
			table.remove(data.Dragons, i)
		end
	end
	return data
end

-- Hors ligne, les œufs continuent d'éclore en temps réel
local function applyOfflineProgress(data)
	local elapsed = math.max(0, os.time() - (data.LastOnline or os.time()))
	for _, entry in data.Incubators do
		local egg = Eggs.ById[entry.EggId]
		entry.Progress = math.min(egg.HatchTime, entry.Progress + elapsed * Config.HatchSpeed.Offline)
	end
end

local function key(player)
	return "player_" .. player.UserId
end

function DataService.Load(player)
	local data = nil
	local canSave = false
	if store then
		for attempt = 1, 3 do
			local ok, result = pcall(function()
				return store:GetAsync(key(player))
			end)
			if ok then
				data = result
				canSave = true
				break
			end
			warn(string.format("[DataService] Échec du chargement (%d/3) pour %s : %s", attempt, player.Name, tostring(result)))
			task.wait(1)
		end
	end
	if not canSave then
		warn("[DataService] Progression de " .. player.Name .. " NON sauvegardée cette session.")
	end

	data = reconcile(data or defaultData())
	applyOfflineProgress(data)

	local profile = { Data = data, CanSave = canSave }
	profiles[player] = profile
	DataService.Sync(player)
	return profile
end

function DataService.Get(player)
	local profile = profiles[player]
	return profile and profile.Data
end

-- Met à jour les infos visibles (classement, interface)
function DataService.Sync(player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	player:SetAttribute("Gold", data.Gold)
	player:SetAttribute("SpeedLevel", data.SpeedLevel)
	player:SetAttribute("IncubatorCount", data.IncubatorCount)

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		local gold = Instance.new("StringValue")
		gold.Name = "Or"
		gold.Parent = leaderstats
		leaderstats.Parent = player
	end
	leaderstats.Or.Value = Format.Number(data.Gold)
end

function DataService.AddGold(player, amount)
	local data = DataService.Get(player)
	if not data then
		return
	end
	data.Gold += amount
	DataService.Sync(player)
end

function DataService.SpendGold(player, amount)
	local data = DataService.Get(player)
	if not data or data.Gold < amount then
		return false
	end
	data.Gold -= amount
	DataService.Sync(player)
	return true
end

function DataService.Save(player)
	local profile = profiles[player]
	if not profile or not profile.CanSave or not store then
		return
	end
	profile.Data.LastOnline = os.time()
	local ok, err = pcall(function()
		store:SetAsync(key(player), profile.Data)
	end)
	if not ok then
		warn("[DataService] Échec de la sauvegarde pour " .. player.Name .. " : " .. tostring(err))
	end
end

function DataService.Release(player)
	DataService.Save(player)
	profiles[player] = nil
end

function DataService.Start()
	task.spawn(function()
		while true do
			task.wait(Config.AutosaveInterval)
			for player in profiles do
				task.spawn(DataService.Save, player)
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for _, player in Players:GetPlayers() do
			pending += 1
			task.spawn(function()
				DataService.Save(player)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

return DataService
