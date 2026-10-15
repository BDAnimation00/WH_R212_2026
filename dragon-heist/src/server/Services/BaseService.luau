-- Bases des joueurs : attribution, panneau, porte verrouillable.
-- Porte verrouillée = mur pour les autres joueurs, mais le propriétaire passe à travers.

local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Visuals = require(script.Parent.Visuals)

local BaseService = {}

local bases = {} -- liste de { Model, Index, Owner, LockedUntil, CooldownUntil, LockPrompt }
local playerBase = {} -- [player] = base

local function doorGroup(base)
	return "Door" .. base.Index
end

local function ownerGroup(base)
	return "Owner" .. base.Index
end

local function registerGroup(name)
	if not PhysicsService:IsCollisionGroupRegistered(name) then
		PhysicsService:RegisterCollisionGroup(name)
	end
end

local function setSign(base)
	local signPart = base.Model:FindFirstChild("Sign")
	local gui = signPart and signPart:FindFirstChildWhichIsA("BillboardGui")
	local label = gui and gui:FindFirstChildWhichIsA("TextLabel")
	if label then
		label.Text = if base.Owner then "Base de " .. base.Owner.DisplayName else "Base libre"
	end
end

function BaseService.IsLocked(base)
	return workspace:GetServerTimeNow() < base.LockedUntil
end

local function updateDoor(base)
	local door = base.Model:FindFirstChild("Door")
	if not door then
		return
	end
	local locked = BaseService.IsLocked(base)
	door.CanCollide = locked
	door.Transparency = if locked then 0.35 else 0.85
	door.Color = if locked then Color3.fromRGB(230, 60, 60) else Color3.fromRGB(80, 220, 120)
	base.Model:SetAttribute("Locked", locked)

	local label = door:FindFirstChild("InfoLabel") and door.InfoLabel:FindFirstChildWhichIsA("TextLabel")
	if label then
		if locked then
			label.Text = "🔒 " .. Format.Time(base.LockedUntil - workspace:GetServerTimeNow())
		elseif base.Owner then
			label.Text = "🔓 Ouvert"
		else
			label.Text = ""
		end
	end
end

local function onLockTriggered(base, player)
	if base.Owner ~= player then
		return
	end
	local now = workspace:GetServerTimeNow()
	if BaseService.IsLocked(base) then
		Remotes.Notify:FireClient(player, "🔒 Ta base est déjà verrouillée.")
		return
	end
	if now < base.CooldownUntil then
		Remotes.Notify:FireClient(player, "⏳ Verrou disponible dans " .. Format.Time(base.CooldownUntil - now))
		return
	end
	base.LockedUntil = now + Config.LockDuration
	base.CooldownUntil = base.LockedUntil + Config.LockCooldown
	updateDoor(base)
	Remotes.Notify:FireClient(player, "🔒 Base verrouillée pour " .. Format.Time(Config.LockDuration) .. " !")
end

function BaseService.Start()
	local folder = workspace:WaitForChild("Map"):WaitForChild("Bases")
	for _, model in folder:GetChildren() do
		local index = tonumber(string.match(model.Name, "%d+"))
		if index then
			table.insert(bases, { Model = model, Index = index, Owner = nil, LockedUntil = 0, CooldownUntil = 0 })
		end
	end
	table.sort(bases, function(a, b)
		return a.Index < b.Index
	end)

	for _, base in bases do
		registerGroup(doorGroup(base))
		registerGroup(ownerGroup(base))
		PhysicsService:CollisionGroupSetCollidable(doorGroup(base), ownerGroup(base), false)
		local door = base.Model:FindFirstChild("Door")
		if door then
			door.CollisionGroup = doorGroup(base)
			Visuals.Label(door, 8, 160)
		end
		setSign(base)
		updateDoor(base)
	end

	task.spawn(function()
		while true do
			task.wait(0.5)
			for _, base in bases do
				updateDoor(base)
			end
		end
	end)
end

function BaseService.Assign(player)
	for _, base in bases do
		if not base.Owner then
			base.Owner = player
			base.LockedUntil = 0
			base.CooldownUntil = 0
			base.Model:SetAttribute("OwnerUserId", player.UserId)
			playerBase[player] = base

			local button = base.Model:FindFirstChild("LockButton")
			if button then
				base.LockPrompt = Visuals.Prompt(button, {
					Name = "LockPrompt",
					ActionText = "Verrouiller",
					ObjectText = "Porte",
					Audience = "Owner",
					OwnerUserId = player.UserId,
				})
				base.LockPrompt.Triggered:Connect(function(who)
					onLockTriggered(base, who)
				end)
			end
			setSign(base)
			updateDoor(base)
			return base
		end
	end
	return nil
end

function BaseService.Release(player)
	local base = playerBase[player]
	if not base then
		return
	end
	playerBase[player] = nil
	base.Owner = nil
	base.LockedUntil = 0
	base.Model:SetAttribute("OwnerUserId", nil)
	if base.LockPrompt then
		base.LockPrompt:Destroy()
		base.LockPrompt = nil
	end
	setSign(base)
	updateDoor(base)
end

function BaseService.GetBase(player)
	return playerBase[player]
end

function BaseService.GetSpawnCFrame(player)
	local base = playerBase[player]
	local spawnPart = base and base.Model:FindFirstChild("Spawn")
	if spawnPart then
		return spawnPart.CFrame * CFrame.new(0, 3, 0)
	end
	return nil
end

-- Le propriétaire passe à travers sa propre porte verrouillée
function BaseService.ApplyOwnerCollision(player, character)
	local base = playerBase[player]
	if not base then
		return
	end
	local group = ownerGroup(base)
	local function apply(part)
		if part:IsA("BasePart") then
			part.CollisionGroup = group
		end
	end
	for _, descendant in character:GetDescendants() do
		apply(descendant)
	end
	character.DescendantAdded:Connect(apply)
end

return BaseService
