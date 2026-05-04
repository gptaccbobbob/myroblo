--!strict
-- Watches every part tagged "Dropper" and spawns drops at the configured
-- interval. The dropper's `ItemId` attribute references an entry in
-- shared/Config/Tycoon. The drop carries the cash value the collector
-- should award when it touches a Collector part in the same plot.

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Tycoon = require(ReplicatedStorage.Shared.Config.Tycoon)
local PlayerDataService = require(script.Parent.Parent.PlayerDataService)

local DROP_LIFETIME = 12 -- safety despawn so drops don't pile up

local activeDroppers: { [BasePart]: thread } = {}

local Dropper = {}

local function getOwner(part: BasePart): Player?
	local plot = part:FindFirstAncestorOfClass("Model")
	if not plot then
		return nil
	end
	local ownerId = plot:GetAttribute("OwnerId")
	if typeof(ownerId) ~= "number" then
		return nil
	end
	return Players:GetPlayerByUserId(ownerId)
end

local DROP_SIZE = 1
local DROP_PHYSICS = PhysicalProperties.new(0.7, 0.1, 0.1)

local function spawnDrop(dropper: BasePart, item: Tycoon.Item, ownerId: number)
	local drop = Instance.new("Part")
	drop.Name = "Drop"
	drop.Size = Vector3.new(DROP_SIZE, DROP_SIZE, DROP_SIZE)
	-- Spawn just below the dropper's bottom face so drops fall onto whatever
	-- surface is below (typically a sloped conveyor leading to a collector).
	drop.CFrame = dropper.CFrame * CFrame.new(0, -dropper.Size.Y / 2 - DROP_SIZE, 0)
	drop.Material = Enum.Material.Neon
	drop.BrickColor = dropper.BrickColor
	drop.CustomPhysicalProperties = DROP_PHYSICS
	drop:SetAttribute("Value", item.dropAmount)
	drop:SetAttribute("OwnerId", ownerId)
	CollectionService:AddTag(drop, "Drop")
	drop.Parent = Workspace
	Debris:AddItem(drop, DROP_LIFETIME)
end

local function attach(part: Instance)
	if not part:IsA("BasePart") then
		return
	end
	if activeDroppers[part] then
		return
	end

	local itemId = part:GetAttribute("ItemId")
	if typeof(itemId) ~= "string" then
		warn(string.format("[Dropper] %s has no ItemId attribute", part:GetFullName()))
		return
	end
	local item = Tycoon.getItem(itemId)
	if not item or item.kind ~= "dropper" then
		warn(
			string.format(
				"[Dropper] %s references unknown dropper item %q",
				part:GetFullName(),
				itemId
			)
		)
		return
	end

	local interval = item.dropInterval or 2

	activeDroppers[part] = task.spawn(function()
		while part.Parent ~= nil do
			task.wait(interval)
			local owner = getOwner(part)
			if owner and PlayerDataService.ownsItem(owner, itemId) then
				spawnDrop(part, item, owner.UserId)
			end
		end
	end)
end

local function detach(part: Instance)
	if not part:IsA("BasePart") then
		return
	end
	local thread = activeDroppers[part]
	if thread then
		task.cancel(thread)
		activeDroppers[part] = nil
	end
end

function Dropper.start()
	for _, part in CollectionService:GetTagged("Dropper") do
		attach(part)
	end
	CollectionService:GetInstanceAddedSignal("Dropper"):Connect(attach)
	CollectionService:GetInstanceRemovedSignal("Dropper"):Connect(detach)
end

return Dropper
