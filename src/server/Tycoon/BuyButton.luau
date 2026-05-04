--!strict
-- Tagged BuyButton parts let the plot owner walk onto them to purchase
-- the item identified by the part's `ItemId` attribute. Cash is deducted,
-- the item is unlocked, and the part is destroyed (one-time purchase).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tycoon = require(ReplicatedStorage.Shared.Config.Tycoon)
local Remotes = require(ReplicatedStorage.Shared.Network.Remotes)
local PlayerDataService = require(script.Parent.Parent.PlayerDataService)

local BuyButton = {}

local function checkRequirements(player: Player, item: Tycoon.Item): (boolean, string?)
	if PlayerDataService.ownsItem(player, item.id) then
		return false, "already owned"
	end
	if item.requires then
		for _, requiredId in item.requires do
			if not PlayerDataService.ownsItem(player, requiredId) then
				local req = Tycoon.getItem(requiredId)
				return false, "requires " .. (req and req.name or requiredId)
			end
		end
	end
	if PlayerDataService.getCash(player) < item.price then
		return false, "not enough cash"
	end
	return true, nil
end

local function onTouched(button: BasePart, otherPart: BasePart)
	local character = otherPart:FindFirstAncestorOfClass("Model")
	if not character then
		return
	end
	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end

	local plot = button:FindFirstAncestorOfClass("Model")
	if not plot or plot:GetAttribute("OwnerId") ~= player.UserId then
		return
	end

	local itemId = button:GetAttribute("ItemId")
	if typeof(itemId) ~= "string" then
		return
	end
	local item = Tycoon.getItem(itemId)
	if not item then
		return
	end

	local ok, reason = checkRequirements(player, item)
	if not ok then
		Remotes.Notify:FireClient(
			player,
			"Cannot buy " .. item.name .. ": " .. (reason or ""),
			"error"
		)
		return
	end

	if not PlayerDataService.spendCash(player, item.price) then
		Remotes.Notify:FireClient(player, "Failed to spend cash", "error")
		return
	end

	PlayerDataService.unlockItem(player, item.id)
	Remotes.Notify:FireClient(player, "Bought: " .. item.name, "success")
	button:Destroy()
end

local function attach(part: Instance)
	if not part:IsA("BasePart") then
		return
	end
	local debounce = false
	part.Touched:Connect(function(other)
		if debounce then
			return
		end
		debounce = true
		onTouched(part, other)
		task.wait(0.5)
		debounce = false
	end)
end

function BuyButton.start()
	for _, part in CollectionService:GetTagged("BuyButton") do
		attach(part)
	end
	CollectionService:GetInstanceAddedSignal("BuyButton"):Connect(attach)
end

return BuyButton
