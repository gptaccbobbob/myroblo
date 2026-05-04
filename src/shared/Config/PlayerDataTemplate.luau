--!strict
-- Default profile data given to a brand-new player on first join.
-- ProfileService:Reconcile() fills in any missing fields when this template
-- is updated, so adding new fields here is safe and won't wipe existing data.

export type PlayerData = {
	Version: number,
	Cash: number,
	OwnedItems: { [string]: boolean },
	TotalEarned: number,
	LastJoinTime: number,
}

local TEMPLATE: PlayerData = {
	Version = 1,
	Cash = 0,
	OwnedItems = {
		-- Starter dropper is always owned so a new player has something running.
		starter_dropper = true,
	},
	TotalEarned = 0,
	LastJoinTime = 0,
}

return TEMPLATE
