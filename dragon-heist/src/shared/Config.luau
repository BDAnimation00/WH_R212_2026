-- RÉGLAGES DU JEU
-- Tous les chiffres d'équilibrage sont ici : change une valeur, sauvegarde, c'est appliqué.
-- Les durées sont en secondes.

local Config = {}

-- Cycle jour / nuit
Config.DayDuration = 600 -- 10 minutes de jour
Config.NightDuration = 150 -- 2 min 30 de nuit

-- Vitesse d'éclosion (1 = temps réel : 1 seconde d'éclosion par seconde)
Config.HatchSpeed = {
	Offline = 1, -- joueur déconnecté : temps réel
	OnlineDay = 2, -- connecté, de jour : 2x plus vite
	OnlineNight = 10, -- connecté, la nuit : 10x plus vite
}

-- Œufs sauvages dans les nids
Config.EggRespawnInterval = 300 -- les nids se remplissent toutes les 5 minutes
Config.EggsPerZone = { [1] = 14, [2] = 10, [3] = 6 } -- œufs par zone (Forêt, Volcan, Ciel) à chaque remplissage
Config.NightRareBoost = 3 -- la nuit, les œufs rares de chaque zone ont 3x plus de chances d'apparaître
Config.AnnounceRarityOrder = 7 -- annonce à tout le serveur à partir de cette rareté (7 = Cosmique)

-- Base
Config.StartIncubators = 3
Config.MaxIncubators = 6
Config.LockDuration = 60 -- la porte reste verrouillée 60 s
Config.LockCooldown = 30 -- puis 30 s avant de pouvoir la reverrouiller

-- Boutique (au centre de la map)
Config.ShopRange = 30 -- distance max du comptoir pour acheter

-- Joueur
Config.BaseWalkSpeed = 16
Config.SpeedPerLevel = 1.5
Config.MaxSpeedLevel = 30
Config.CarrySpeedMultiplier = 0.75 -- porter un œuf ralentit
Config.StealHoldDuration = 2 -- temps à maintenir la touche pour voler

-- Économie
Config.StartGold = 0
Config.SellSeconds = 120 -- un dragon se revend pour 120 secondes de ses revenus

function Config.SpeedCost(level)
	return math.floor(25 * 1.55 ^ level)
end

-- count = nombre d'incubateurs déjà possédés
function Config.IncubatorCost(count)
	return math.floor(500 * 6 ^ (count - Config.StartIncubators))
end

-- Mutations tirées à l'éclosion (testées de la plus rare à la plus commune)
Config.Mutations = {
	{ Name = "Arc-en-ciel", Chance = 0.01, Multiplier = 3, Color = Color3.fromRGB(255, 120, 230) },
	{ Name = "Doré", Chance = 0.04, Multiplier = 2, Color = Color3.fromRGB(255, 205, 60) },
	{ Name = "Argenté", Chance = 0.06, Multiplier = 1.2, Color = Color3.fromRGB(205, 215, 230) },
}

-- Mutation spéciale qui n'existe que si l'œuf éclot la nuit
Config.NightMutation = { Name = "Lunaire", Chance = 0.05, Multiplier = 2.5, Color = Color3.fromRGB(120, 160, 255) }

function Config.GetMutation(name)
	if name == nil then
		return nil
	end
	if name == Config.NightMutation.Name then
		return Config.NightMutation
	end
	for _, mutation in Config.Mutations do
		if mutation.Name == name then
			return mutation
		end
	end
	return nil
end

-- Sauvegarde
Config.DataStoreName = "DragonHeist_v1"
Config.AutosaveInterval = 120

return Config
