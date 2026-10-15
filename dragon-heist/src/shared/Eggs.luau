-- LISTE DES ŒUFS ET DES RARETÉS
-- Pour ajouter un œuf : copie une ligne de Eggs.List et change les valeurs.
--   Id         : identifiant unique (sert aussi de nom au modèle 3D dans ReplicatedStorage/Assets/Eggs et Assets/Dragons)
--   Zone       : 1 = Forêt, 2 = Volcan, 3 = Ciel
--   Weight     : chance relative d'apparaître dans sa zone
--   HatchTime  : temps d'éclosion en temps réel (secondes)
--   Income     : or rapporté par seconde par le dragon

local Eggs = {}

Eggs.Rarities = {
	Common = { Order = 1, Label = "Commun", Color = Color3.fromRGB(190, 190, 190) },
	Uncommon = { Order = 2, Label = "Peu commun", Color = Color3.fromRGB(90, 200, 90) },
	Rare = { Order = 3, Label = "Rare", Color = Color3.fromRGB(70, 140, 255) },
	Epic = { Order = 4, Label = "Épique", Color = Color3.fromRGB(170, 80, 255) },
	Legendary = { Order = 5, Label = "Légendaire", Color = Color3.fromRGB(255, 170, 30) },
	Mythic = { Order = 6, Label = "Mythique", Color = Color3.fromRGB(255, 60, 90) },
	Cosmic = { Order = 7, Label = "Cosmique", Color = Color3.fromRGB(60, 230, 230) },
	Secret = { Order = 8, Label = "Secret", Color = Color3.fromRGB(40, 40, 40) },
	Eternal = { Order = 9, Label = "Éternel", Color = Color3.fromRGB(255, 255, 255) },
}

Eggs.Zones = {
	[1] = "Forêt",
	[2] = "Volcan",
	[3] = "Ciel",
}

local MINUTE = 60
local HOUR = 3600

Eggs.List = {
	-- Forêt
	{ Id = "Ember", EggName = "Œuf de Braise", DragonName = "Dragonnet de Braise", Rarity = "Common", Zone = 1, Weight = 60, HatchTime = 10, Income = 1 },
	{ Id = "Moss", EggName = "Œuf de Mousse", DragonName = "Dragon Mousse", Rarity = "Uncommon", Zone = 1, Weight = 30, HatchTime = 1 * MINUTE, Income = 3 },
	{ Id = "Storm", EggName = "Œuf d'Orage", DragonName = "Dragon d'Orage", Rarity = "Rare", Zone = 1, Weight = 10, HatchTime = 5 * MINUTE, Income = 10 },
	-- Volcan
	{ Id = "Magma", EggName = "Œuf de Magma", DragonName = "Dragon de Magma", Rarity = "Rare", Zone = 2, Weight = 55, HatchTime = 6 * MINUTE, Income = 14 },
	{ Id = "Obsidian", EggName = "Œuf d'Obsidienne", DragonName = "Dragon d'Obsidienne", Rarity = "Epic", Zone = 2, Weight = 35, HatchTime = 20 * MINUTE, Income = 40 },
	{ Id = "Solar", EggName = "Œuf Solaire", DragonName = "Dragon Solaire", Rarity = "Legendary", Zone = 2, Weight = 10, HatchTime = 1 * HOUR, Income = 150 },
	-- Ciel
	{ Id = "Celestial", EggName = "Œuf Céleste", DragonName = "Dragon Céleste", Rarity = "Mythic", Zone = 3, Weight = 70, HatchTime = 3 * HOUR, Income = 500 },
	{ Id = "Nebula", EggName = "Œuf Nébuleuse", DragonName = "Dragon Nébuleuse", Rarity = "Cosmic", Zone = 3, Weight = 25, HatchTime = 6 * HOUR, Income = 1500 },
	{ Id = "Void", EggName = "Œuf du Néant", DragonName = "Dragon du Néant", Rarity = "Secret", Zone = 3, Weight = 4.5, HatchTime = 12 * HOUR, Income = 5000 },
	{ Id = "Primordial", EggName = "Œuf Primordial", DragonName = "Dragon Primordial", Rarity = "Eternal", Zone = 3, Weight = 0.5, HatchTime = 20 * HOUR, Income = 20000 },
}

Eggs.ById = {}
for _, egg in Eggs.List do
	Eggs.ById[egg.Id] = egg
end

function Eggs.GetRarity(eggId)
	local egg = Eggs.ById[eggId]
	return egg and Eggs.Rarities[egg.Rarity]
end

-- Tire un œuf au hasard dans une zone.
-- La nuit, tous les œufs de la zone sauf le plus commun sont boostés (x nightBoost).
function Eggs.Roll(zone, isNight, nightBoost, rng)
	local maxWeight = 0
	for _, egg in Eggs.List do
		if egg.Zone == zone then
			maxWeight = math.max(maxWeight, egg.Weight)
		end
	end

	local candidates = {}
	local total = 0
	for _, egg in Eggs.List do
		if egg.Zone == zone then
			local weight = egg.Weight
			if isNight and egg.Weight < maxWeight then
				weight *= nightBoost
			end
			total += weight
			table.insert(candidates, { Egg = egg, Weight = weight })
		end
	end
	if total <= 0 then
		return nil
	end
	local roll = rng:NextNumber() * total
	for _, candidate in candidates do
		roll -= candidate.Weight
		if roll <= 0 then
			return candidate.Egg
		end
	end
	return candidates[#candidates].Egg
end

return Eggs
