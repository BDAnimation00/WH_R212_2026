-- Cycle jour / nuit. La nuit, les œufs éclosent beaucoup plus vite (voir Config.HatchSpeed).
-- L'état est publié dans les attributs de ReplicatedStorage pour l'interface des joueurs :
--   IsNight (bool), PhaseEndsAt (heure serveur de fin de la phase)

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DayNightService = {}

local isNight = false

function DayNightService.IsNight()
	return isNight
end

function DayNightService.GetHatchRate()
	return if isNight then Config.HatchSpeed.OnlineNight else Config.HatchSpeed.OnlineDay
end

local function setPhase(night, duration)
	isNight = night
	ReplicatedStorage:SetAttribute("IsNight", night)
	ReplicatedStorage:SetAttribute("PhaseEndsAt", workspace:GetServerTimeNow() + duration)

	TweenService:Create(Lighting, TweenInfo.new(4), {
		ClockTime = if night then 21.5 else 13,
		Brightness = if night then 0.6 else 2,
	}):Play()

	if night then
		Remotes.Notify:FireAllClients(string.format(
			"🌙 La nuit tombe ! Éclosion x%d pendant %s !",
			Config.HatchSpeed.OnlineNight,
			Format.Time(duration)
		))
	else
		Remotes.Notify:FireAllClients("☀️ Le jour se lève.")
	end
end

function DayNightService.Start()
	task.spawn(function()
		while true do
			setPhase(false, Config.DayDuration)
			task.wait(Config.DayDuration)
			setPhase(true, Config.NightDuration)
			task.wait(Config.NightDuration)
		end
	end)
end

return DayNightService
