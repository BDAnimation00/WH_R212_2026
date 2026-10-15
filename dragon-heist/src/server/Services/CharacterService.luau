-- Personnage : vitesse de marche, œuf porté au-dessus de la tête, apparition dans sa base.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Eggs = require(ReplicatedStorage.Shared.Eggs)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)
local BaseService = require(script.Parent.BaseService)
local Visuals = require(script.Parent.Visuals)

local CharacterService = {}

local carrying = {} -- [player] = { EggId, Progress, Visual }

function CharacterService.GetWalkSpeed(player)
	local data = DataService.Get(player)
	local level = if data then data.SpeedLevel else 0
	local speed = Config.BaseWalkSpeed + level * Config.SpeedPerLevel
	if carrying[player] then
		speed *= Config.CarrySpeedMultiplier
	end
	return speed
end

function CharacterService.Refresh(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = CharacterService.GetWalkSpeed(player)
	end
end

function CharacterService.GetCarried(player)
	return carrying[player]
end

function CharacterService.StartCarry(player, eggId, progress)
	if carrying[player] then
		return false
	end
	local head = player.Character and player.Character:FindFirstChild("Head")
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not head or not humanoid or humanoid.Health <= 0 then
		return false
	end

	local visual = Visuals.Egg(eggId, false)
	visual:PivotTo(head.CFrame * CFrame.new(0, 2.6, 0))
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = head
	weld.Part1 = visual.PrimaryPart
	weld.Parent = visual.PrimaryPart
	visual.Parent = player.Character

	carrying[player] = { EggId = eggId, Progress = progress or 0, Visual = visual }
	player:SetAttribute("CarryingEgg", Eggs.ById[eggId].EggName)
	CharacterService.Refresh(player)
	return true
end

-- Retire l'œuf porté et le renvoie (ou nil)
function CharacterService.StopCarry(player)
	local carried = carrying[player]
	if not carried then
		return nil
	end
	carrying[player] = nil
	if carried.Visual then
		carried.Visual:Destroy()
	end
	player:SetAttribute("CarryingEgg", nil)
	CharacterService.Refresh(player)
	return carried
end

local function onCharacterAdded(player, character)
	carrying[player] = nil
	player:SetAttribute("CarryingEgg", nil)

	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")
	BaseService.ApplyOwnerCollision(player, character)
	CharacterService.Refresh(player)

	local spawnCFrame = BaseService.GetSpawnCFrame(player)
	if spawnCFrame then
		task.delay(0.1, function()
			if root.Parent then
				root.CFrame = spawnCFrame
			end
		end)
	end

	humanoid.Died:Connect(function()
		if CharacterService.StopCarry(player) then
			Remotes.Notify:FireClient(player, "💥 Tu as perdu l'œuf que tu portais !")
		end
	end)
end

function CharacterService.Setup(player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end
end

function CharacterService.Cleanup(player)
	CharacterService.StopCarry(player)
end

Players.PlayerRemoving:Connect(function(player)
	carrying[player] = nil
end)

return CharacterService
