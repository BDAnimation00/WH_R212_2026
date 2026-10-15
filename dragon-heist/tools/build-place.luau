-- Génère DragonHeist.rbxlx : le code (compilé par Rojo) + la map de base (WorldBuilder).
-- Utilisation : rojo build default.project.json -o build/code.rbxlx && lune run tools/build-place.luau

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

local game = roblox.deserializePlace(fs.readFile("build/code.rbxlx"))

local env = setmetatable({
	Instance = roblox.Instance,
	Vector3 = roblox.Vector3,
	CFrame = roblox.CFrame,
	Color3 = roblox.Color3,
	UDim2 = roblox.UDim2,
	UDim = roblox.UDim,
	Enum = roblox.Enum,
}, { __index = _G })

local WorldBuilder = luau.load(fs.readFile("src/server/WorldBuilder.luau"), {
	debugName = "WorldBuilder",
	environment = env,
})()

local workspace = game:GetService("Workspace")
local map = WorldBuilder.Build()
map.Parent = workspace

local lighting = game:GetService("Lighting")
lighting.ClockTime = 13

-- Dossiers vides où déposer les modèles 3D (ils remplacent les placeholders automatiquement)
local replicatedStorage = game:GetService("ReplicatedStorage")
local assets = roblox.Instance.new("Folder")
assets.Name = "Assets"
for _, name in { "Eggs", "Dragons" } do
	local folder = roblox.Instance.new("Folder")
	folder.Name = name
	folder.Parent = assets
end
assets.Parent = replicatedStorage

fs.writeFile("DragonHeist.rbxlx", roblox.serializePlace(game, true))
print("DragonHeist.rbxlx généré")
