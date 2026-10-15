-- Création des visuels : œufs, dragons, étiquettes et prompts d'interaction.
-- Si tu mets un modèle dans ReplicatedStorage/Assets/Eggs/<Id> ou Assets/Dragons/<Id>,
-- il remplace automatiquement le placeholder (cube / sphère).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Eggs = require(ReplicatedStorage.Shared.Eggs)

local Visuals = {}

local function findAsset(kind, id)
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local folder = assets and assets:FindFirstChild(kind)
	local asset = folder and folder:FindFirstChild(id)
	if asset and asset:IsA("Model") then
		return asset:Clone()
	end
	return nil
end

-- Rend un modèle déplaçable d'un bloc : tout est soudé à la PrimaryPart, rien ne bloque les joueurs.
local function prepare(model, anchored)
	if not model.PrimaryPart then
		model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart", true)
	end
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = anchored
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.Massless = true
			if descendant ~= model.PrimaryPart then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = model.PrimaryPart
				weld.Part1 = descendant
				weld.Parent = descendant
			end
		end
	end
	return model
end

function Visuals.Egg(eggId, anchored)
	local model = findAsset("Eggs", eggId)
	if not model then
		local rarity = Eggs.GetRarity(eggId)
		model = Instance.new("Model")
		local shell = Instance.new("Part")
		shell.Name = "Shell"
		shell.Size = Vector3.new(2, 2.6, 2)
		shell.Color = rarity.Color
		shell.Material = if rarity.Order >= 5 then Enum.Material.Neon else Enum.Material.SmoothPlastic
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = shell
		shell.Parent = model
		model.PrimaryPart = shell
	end
	model.Name = "Egg_" .. eggId
	return prepare(model, anchored)
end

function Visuals.Dragon(eggId, mutationName)
	local mutation = Config.GetMutation(mutationName)
	local model = findAsset("Dragons", eggId)
	if model then
		if mutation then
			local highlight = Instance.new("Highlight")
			highlight.FillColor = mutation.Color
			highlight.FillTransparency = 0.6
			highlight.OutlineColor = mutation.Color
			highlight.Parent = model
		end
	else
		local rarity = Eggs.GetRarity(eggId)
		local color = if mutation then mutation.Color else rarity.Color
		model = Instance.new("Model")
		local body = Instance.new("Part")
		body.Name = "Body"
		body.Size = Vector3.new(3, 2.5, 4)
		body.Color = color
		body.Parent = model
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Size = Vector3.new(2, 2, 2)
		head.Color = color
		head.CFrame = body.CFrame * CFrame.new(0, 1.5, -2.2)
		head.Parent = model
		local wing = Instance.new("Part")
		wing.Name = "Wings"
		wing.Size = Vector3.new(7, 0.3, 2)
		wing.Color = color:Lerp(Color3.new(0, 0, 0), 0.25)
		wing.CFrame = body.CFrame * CFrame.new(0, 1.4, 0.5)
		wing.Parent = model
		model.PrimaryPart = body
	end
	model.Name = "Dragon_" .. eggId
	return prepare(model, true)
end

-- Étiquette flottante (texte enrichi : <font color="#ff0000">...</font> possible)
function Visuals.Label(adornee, offsetY, width)
	local gui = Instance.new("BillboardGui")
	gui.Name = "InfoLabel"
	gui.Size = UDim2.new(0, width or 200, 0, 70)
	gui.StudsOffset = Vector3.new(0, offsetY, 0)
	gui.MaxDistance = 80
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.RichText = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Parent = gui
	gui.Adornee = adornee
	gui.Parent = adornee
	return label
end

-- Prompt d'interaction.
-- audience = "All" (tout le monde), "Owner" (propriétaire de la base) ou "Others" (les autres joueurs).
-- L'affichage est filtré côté joueur ; le serveur revérifie toujours tout.
function Visuals.Prompt(parent, options)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = options.Name or "Prompt"
	prompt.ActionText = options.ActionText or ""
	prompt.ObjectText = options.ObjectText or ""
	prompt.HoldDuration = options.HoldDuration or 0
	prompt.MaxActivationDistance = options.Distance or 10
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = options.Key or Enum.KeyCode.E
	prompt:SetAttribute("Audience", options.Audience or "All")
	prompt:SetAttribute("OwnerUserId", options.OwnerUserId or 0)
	prompt:SetAttribute("Active", options.Active ~= false)
	CollectionService:AddTag(prompt, "DHPrompt")
	prompt.Parent = parent
	return prompt
end

function Visuals.Colorize(text, color)
	return string.format('<font color="#%s">%s</font>', color:ToHex(), text)
end

return Visuals
