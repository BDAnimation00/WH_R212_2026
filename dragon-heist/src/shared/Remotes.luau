-- Canaux de communication serveur <-> joueurs. Le serveur les crée, les joueurs les attendent.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NAMES = { "Notify", "HatchReveal", "UpgradeSpeed" }

local folder
if RunService:IsServer() then
	folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	for _, name in NAMES do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	end
else
	folder = ReplicatedStorage:WaitForChild("Remotes")
end

local Remotes = {}
for _, name in NAMES do
	Remotes[name] = folder:WaitForChild(name)
end

return Remotes
