--!strict
-- Catalog of items the player can buy via BuyButtons.
-- Add or change entries here, then place a BuyButton with a matching `ItemId`
-- attribute in the world.

export type ItemKind = "dropper" | "collector" | "upgrade" | "cosmetic"

export type Item = {
	id: string,
	name: string,
	price: number,
	kind: ItemKind,
	-- Other items that must be owned before this one can be bought.
	requires: { string }?,
	-- Dropper-specific.
	dropAmount: number?,
	dropInterval: number?,
	-- Upgrade-specific (multiplier applied to player's earnings).
	earningsMultiplier: number?,
}

local items: { Item } = {
	{
		id = "starter_dropper",
		name = "Starter Dropper",
		price = 0,
		kind = "dropper",
		dropAmount = 1,
		dropInterval = 2,
	},
	{
		id = "iron_dropper",
		name = "Iron Dropper",
		price = 100,
		requires = { "starter_dropper" },
		kind = "dropper",
		dropAmount = 5,
		dropInterval = 2,
	},
	{
		id = "gold_dropper",
		name = "Gold Dropper",
		price = 1_000,
		requires = { "iron_dropper" },
		kind = "dropper",
		dropAmount = 25,
		dropInterval = 2,
	},
	{
		id = "x2_multiplier",
		name = "2× Earnings",
		price = 5_000,
		requires = { "gold_dropper" },
		kind = "upgrade",
		earningsMultiplier = 2,
	},
}

local Config = {}

Config.Items = items

-- Map from id -> item for O(1) lookup.
Config.ItemsById = (function(): { [string]: Item }
	local map: { [string]: Item } = {}
	for _, item in items do
		map[item.id] = item
	end
	return map
end)()

function Config.getItem(id: string): Item?
	return Config.ItemsById[id]
end

return Config
