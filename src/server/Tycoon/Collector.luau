--!strict
-- Awards cash when a tagged Drop touches a tagged Collector in the same plot.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tycoon = require(ReplicatedStorage.Shared.Config.Tycoon)
local PlayerDataService = require(script.Parent.Parent.PlayerDataService)

local Collector = {}

local function getMultiplier(player: Player): number
	if PlayerDataService.ownsItem(player, "x2_multiplier") then
		local item = Tycoon.getItem("x2_multiplier")
		if item and item.earningsMultiplier then
			return item.earningsMultiplier
		end
	end
	return 1
end

local function onTouched(collector: BasePart, otherPart: BasePart)
	if not CollectionService:HasTag(otherPart, "Drop") then
		return
	end

	local dropOwnerId = otherPart:GetAttribute("OwnerId")
	if typeof(dropOwnerId) ~= "number" then
		return
	end

	-- Drops only count for the owner of the plot they were dropped in.
	local plot = collector:FindFirstAncestorOfClass("Model")
	if not plot or plot:GetAttribute("OwnerId") ~= dropOwnerId then
		return
	end

	local owner = Players:GetPlayerByUserId(dropOwnerId)
	if not owner then
		return
	end

	local value = otherPart:GetAttribute("Value")
	if typeof(value) ~= "number" then
		return
	end

	PlayerDataService.addCash(owner, math.floor(value * getMultiplier(owner)))
	otherPart:Destroy()
end

local function attach(part: Instance)
	if not part:IsA("BasePart") then
		return
	end
	part.Touched:Connect(function(other)
		onTouched(part, other)
	end)
end

function Collector.start()
	for _, part in CollectionService:GetTagged("Collector") do
		attach(part)
	end
	CollectionService:GetInstanceAddedSignal("Collector"):Connect(attach)
end

return Collector
