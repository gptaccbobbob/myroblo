--!strict
-- Lazily creates RemoteEvents under ReplicatedStorage.Remotes.
-- Both server and client use this; it's safe to call from either side.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "Remotes"

local function getOrCreateFolder(): Folder
	local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if existing and existing:IsA("Folder") then
		return existing
	end
	if RunService:IsServer() then
		local folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
		return folder
	end
	return ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
end

local folder = getOrCreateFolder()

local function getRemoteEvent(name: string): RemoteEvent
	local existing = folder:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	if RunService:IsServer() then
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
		return remote
	end
	return folder:WaitForChild(name) :: RemoteEvent
end

local Remotes = {
	-- Server -> client: the player's Cash value just changed.
	-- Payload: (newCash: number)
	CashChanged = getRemoteEvent("CashChanged"),

	-- Server -> client: the player's owned-items set just changed.
	-- Payload: (ownedItems: { [string]: boolean })
	OwnedItemsChanged = getRemoteEvent("OwnedItemsChanged"),

	-- Server -> client: show a transient toast / notification.
	-- Payload: (message: string, kind: "info" | "success" | "error")
	Notify = getRemoteEvent("Notify"),
}

return Remotes
