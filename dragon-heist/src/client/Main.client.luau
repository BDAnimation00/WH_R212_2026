-- Interface du joueur : jour/nuit, prochain remplissage des nids, or, vitesse, notifications, éclosion.
-- Le style (couleurs, polices, tailles) se change dans la section STYLE.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Eggs = require(Shared.Eggs)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)

local player = Players.LocalPlayer

-- STYLE
local FONT = Enum.Font.FredokaOne
local PANEL_COLOR = Color3.fromRGB(25, 25, 35)
local TEXT_COLOR = Color3.fromRGB(255, 255, 255)
local GOLD_COLOR = Color3.fromRGB(255, 205, 60)
local NIGHT_COLOR = Color3.fromRGB(120, 160, 255)
local DAY_COLOR = Color3.fromRGB(255, 220, 120)

local gui = Instance.new("ScreenGui")
gui.Name = "DragonHeistHUD"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local function round(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 12)
	corner.Parent = instance
end

local function label(props)
	local l = Instance.new("TextLabel")
	l.BackgroundColor3 = PANEL_COLOR
	l.BackgroundTransparency = 0.25
	l.Font = FONT
	l.TextColor3 = TEXT_COLOR
	l.TextScaled = true
	l.RichText = true
	for key, value in props do
		l[key] = value
	end
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 4)
	padding.Parent = l
	round(l)
	l.Parent = props.Parent or gui
	return l
end

-- Haut de l'écran : jour / nuit + nids
local phaseLabel = label({
	Name = "Phase",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 8),
	Size = UDim2.new(0, 360, 0, 40),
})
local nestLabel = label({
	Name = "Nests",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 52),
	Size = UDim2.new(0, 260, 0, 28),
})

-- Gauche : or
local goldLabel = label({
	Name = "Gold",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 12, 0.4, 0),
	Size = UDim2.new(0, 190, 0, 46),
	TextColor3 = GOLD_COLOR,
	TextXAlignment = Enum.TextXAlignment.Left,
})
local incomeLabel = label({
	Name = "Income",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 12, 0.4, 40),
	Size = UDim2.new(0, 150, 0, 28),
	TextXAlignment = Enum.TextXAlignment.Left,
})

-- Bas : œuf porté + bouton vitesse
local carryLabel = label({
	Name = "Carry",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -24),
	Size = UDim2.new(0, 420, 0, 34),
	Visible = false,
})

-- Fenêtre Boutique (s'ouvre au comptoir, au centre de la map)
local shopPanel = Instance.new("Frame")
shopPanel.Name = "ShopPanel"
shopPanel.AnchorPoint = Vector2.new(0.5, 0.5)
shopPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
shopPanel.Size = UDim2.new(0, 360, 0, 230)
shopPanel.BackgroundColor3 = PANEL_COLOR
shopPanel.BackgroundTransparency = 0.1
shopPanel.Visible = false
round(shopPanel, 18)
shopPanel.Parent = gui

label({
	Parent = shopPanel,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 0, 0, 10),
	Size = UDim2.new(1, 0, 0, 44),
	Text = "🛒 BOUTIQUE",
	TextColor3 = GOLD_COLOR,
})

local closeButton = Instance.new("TextButton")
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -8, 0, 8)
closeButton.Size = UDim2.new(0, 36, 0, 36)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeButton.Font = FONT
closeButton.Text = "X"
closeButton.TextColor3 = TEXT_COLOR
closeButton.TextScaled = true
round(closeButton, 10)
closeButton.Parent = shopPanel

local speedButton = Instance.new("TextButton")
speedButton.Name = "SpeedButton"
speedButton.AnchorPoint = Vector2.new(0.5, 0)
speedButton.Position = UDim2.new(0.5, 0, 0, 70)
speedButton.Size = UDim2.new(1, -40, 0, 56)
speedButton.BackgroundColor3 = Color3.fromRGB(60, 170, 255)
speedButton.Font = FONT
speedButton.TextColor3 = TEXT_COLOR
speedButton.TextScaled = true
speedButton.AutoButtonColor = true
round(speedButton)
speedButton.Parent = shopPanel
speedButton.Activated:Connect(function()
	Remotes.UpgradeSpeed:FireServer()
end)

label({
	Parent = shopPanel,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 0, 0, 140),
	Size = UDim2.new(1, 0, 0, 70),
	Text = "Bientôt : boosts de chance, œufs premium, game passes",
	TextColor3 = Color3.fromRGB(170, 170, 190),
})

local shopPosition = nil
local function closeShop()
	shopPanel.Visible = false
	shopPosition = nil
end
closeButton.Activated:Connect(closeShop)
Remotes.OpenShop.OnClientEvent:Connect(function(position)
	shopPosition = position
	shopPanel.Visible = true
end)

-- Notifications (à droite)
local toastList = Instance.new("Frame")
toastList.Name = "Toasts"
toastList.AnchorPoint = Vector2.new(1, 0)
toastList.Position = UDim2.new(1, -12, 0, 90)
toastList.Size = UDim2.new(0, 340, 0.6, 0)
toastList.BackgroundTransparency = 1
toastList.Parent = gui
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = toastList

local toastCount = 0
local function toast(text)
	toastCount += 1
	local t = label({
		Parent = toastList,
		LayoutOrder = toastCount,
		Size = UDim2.new(1, 0, 0, 40),
		Text = text,
		TextTransparency = 1,
		BackgroundTransparency = 1,
	})
	TweenService:Create(t, TweenInfo.new(0.25), { TextTransparency = 0, BackgroundTransparency = 0.25 }):Play()
	task.delay(4.5, function()
		local out = TweenService:Create(t, TweenInfo.new(0.4), { TextTransparency = 1, BackgroundTransparency = 1 })
		out:Play()
		out.Completed:Wait()
		t:Destroy()
	end)
end
Remotes.Notify.OnClientEvent:Connect(toast)

-- Animation d'éclosion
local function showHatch(eggId, mutationName)
	local egg = Eggs.ById[eggId]
	if not egg then
		return
	end
	local rarity = Eggs.Rarities[egg.Rarity]
	local mutation = Config.GetMutation(mutationName)

	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.new(0.5, 0, 0.45, 0)
	frame.Size = UDim2.new(0, 0, 0, 0)
	frame.BackgroundColor3 = PANEL_COLOR
	frame.BackgroundTransparency = 0.1
	round(frame, 20)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = rarity.Color
	stroke.Parent = frame
	frame.Parent = gui

	local title = label({
		Parent = frame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0.08, 0),
		Size = UDim2.new(1, 0, 0.4, 0),
		Text = "🥚",
	})
	local subtitle = label({
		Parent = frame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0.55, 0),
		Size = UDim2.new(1, 0, 0.3, 0),
		Text = "...",
	})

	TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Size = UDim2.new(0, 380, 0, 200) }):Play()

	-- Suspense : l'œuf tremble
	for i = 1, 8 do
		title.Rotation = if i % 2 == 0 then 12 else -12
		task.wait(0.12)
	end
	title.Rotation = 0

	local name = egg.DragonName
	if mutation then
		name = string.format('<font color="#%s">%s</font> %s', mutation.Color:ToHex(), mutation.Name, name)
	end
	title.Text = name
	subtitle.Text = string.format('<font color="#%s">%s</font>', rarity.Color:ToHex(), rarity.Label)
	title.Size = UDim2.new(1, 0, 0.3, 0)
	title.Position = UDim2.new(0, 0, 0.15, 0)

	task.wait(3)
	local out = TweenService:Create(frame, TweenInfo.new(0.25), { Size = UDim2.new(0, 0, 0, 0) })
	out:Play()
	out.Completed:Wait()
	frame:Destroy()
end
Remotes.HatchReveal.OnClientEvent:Connect(function(eggId, mutationName)
	task.spawn(showHatch, eggId, mutationName)
end)

-- Affichage des prompts selon le joueur (propriétaire / visiteur)
local function refreshPrompt(prompt)
	local active = prompt:GetAttribute("Active") ~= false
	local audience = prompt:GetAttribute("Audience") or "All"
	local isOwner = prompt:GetAttribute("OwnerUserId") == player.UserId
	prompt.Enabled = active
		and (audience == "All" or (audience == "Owner" and isOwner) or (audience == "Others" and not isOwner))
end
local function watchPrompt(prompt)
	if not prompt:IsA("ProximityPrompt") then
		return
	end
	refreshPrompt(prompt)
	prompt.AttributeChanged:Connect(function()
		refreshPrompt(prompt)
	end)
end
CollectionService:GetInstanceAddedSignal("DHPrompt"):Connect(watchPrompt)
for _, prompt in CollectionService:GetTagged("DHPrompt") do
	watchPrompt(prompt)
end

-- Ta base : tes murs sont semi-transparents pour toi (tu peux les traverser, pas les autres)
local OWN_WALL_TRANSPARENCY = 0.6
local function isOwnerPassable(instance)
	return instance:IsA("BasePart")
		and (string.sub(instance.Name, 1, 4) == "Wall" or instance:GetAttribute("OwnerPassable") == true)
end
local function refreshBase(base)
	local mine = base:GetAttribute("OwnerUserId") == player.UserId
	for _, descendant in base:GetDescendants() do
		if isOwnerPassable(descendant) then
			if descendant:GetAttribute("BaseTransparency") == nil then
				descendant:SetAttribute("BaseTransparency", descendant.Transparency)
			end
			local original = descendant:GetAttribute("BaseTransparency")
			descendant.Transparency = if mine then math.max(original, OWN_WALL_TRANSPARENCY) else original
		end
	end
end
task.spawn(function()
	local bases = workspace:WaitForChild("Map"):WaitForChild("Bases")
	local function watchBase(base)
		refreshBase(base)
		base:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
			refreshBase(base)
		end)
	end
	for _, base in bases:GetChildren() do
		watchBase(base)
	end
	bases.ChildAdded:Connect(watchBase)
end)

-- Mises à jour
local function refreshStats()
	goldLabel.Text = "💰 " .. Format.Number(player:GetAttribute("Gold") or 0)
	incomeLabel.Text = "+" .. Format.Number(player:GetAttribute("IncomePerSecond") or 0) .. " /s"

	local level = player:GetAttribute("SpeedLevel") or 0
	if level >= Config.MaxSpeedLevel then
		speedButton.Text = "⚡ Vitesse MAX"
	else
		speedButton.Text = string.format("⚡ Vitesse Nv.%d → %d  (💰 %s)", level, level + 1, Format.Number(Config.SpeedCost(level)))
	end

	local carrying = player:GetAttribute("CarryingEgg")
	carryLabel.Visible = carrying ~= nil
	if carrying then
		carryLabel.Text = "🥚 " .. carrying .. " — ramène-le dans ta base !"
	end
end
player.AttributeChanged:Connect(refreshStats)
refreshStats()

local accumulator = 0
RunService.Heartbeat:Connect(function(dt)
	accumulator += dt
	if accumulator < 0.2 then
		return
	end
	accumulator = 0

	local now = workspace:GetServerTimeNow()
	local isNight = ReplicatedStorage:GetAttribute("IsNight")
	local phaseLeft = (ReplicatedStorage:GetAttribute("PhaseEndsAt") or now) - now
	if isNight then
		phaseLabel.Text = string.format("🌙 NUIT — Éclosion x%d ! (%s)", Config.HatchSpeed.OnlineNight, Format.Time(phaseLeft))
		phaseLabel.TextColor3 = NIGHT_COLOR
	else
		phaseLabel.Text = "☀️ Jour — la nuit tombe dans " .. Format.Time(phaseLeft)
		phaseLabel.TextColor3 = DAY_COLOR
	end

	local nestLeft = (ReplicatedStorage:GetAttribute("EggRespawnAt") or now) - now
	nestLabel.Text = "🥚 Nouveaux œufs dans " .. Format.Time(nestLeft)

	-- La boutique se ferme quand on s'éloigne du comptoir
	if shopPosition then
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not root or (root.Position - shopPosition).Magnitude > Config.ShopRange then
			closeShop()
		end
	end
end)
