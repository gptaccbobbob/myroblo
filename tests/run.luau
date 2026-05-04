--!strict
-- Lune-based smoke tests for things that don't require a running Roblox engine.
-- Run with: `lune run tests/run`

local Tycoon = require("../src/shared/Config/Tycoon")
local PlayerDataTemplate = require("../src/shared/Config/PlayerDataTemplate")

local failures = 0
local total = 0

local function check(condition: boolean, message: string)
	total += 1
	if condition then
		print("  [PASS] " .. message)
	else
		print("  [FAIL] " .. message)
		failures += 1
	end
end

print("== Tycoon config ==")

-- Every item id is unique.
do
	local seen: { [string]: boolean } = {}
	for _, item in Tycoon.Items do
		check(not seen[item.id], "unique id: " .. item.id)
		seen[item.id] = true
	end
end

-- Every `requires` references an existing item.
for _, item in Tycoon.Items do
	if item.requires then
		for _, requiredId in item.requires do
			check(
				Tycoon.ItemsById[requiredId] ~= nil,
				string.format("%s requires existing item %q", item.id, requiredId)
			)
		end
	end
end

-- Prices are non-negative.
for _, item in Tycoon.Items do
	check(item.price >= 0, string.format("%s has non-negative price", item.id))
end

-- Droppers have positive dropAmount and dropInterval.
for _, item in Tycoon.Items do
	if item.kind == "dropper" then
		check(
			(item.dropAmount or 0) > 0,
			string.format("dropper %s has positive dropAmount", item.id)
		)
		check(
			(item.dropInterval or 0) > 0,
			string.format("dropper %s has positive dropInterval", item.id)
		)
	end
end

-- Upgrades have a multiplier > 1.
for _, item in Tycoon.Items do
	if item.kind == "upgrade" then
		check(
			(item.earningsMultiplier or 0) > 1,
			string.format("upgrade %s has multiplier > 1", item.id)
		)
	end
end

print("== PlayerDataTemplate ==")
check(PlayerDataTemplate.Cash == 0, "starting cash is 0")
check(type(PlayerDataTemplate.OwnedItems) == "table", "OwnedItems is a table")
check(
	PlayerDataTemplate.OwnedItems["starter_dropper"] == true,
	"new players own the starter_dropper"
)
check(PlayerDataTemplate.Version >= 1, "Version is >= 1")

print(string.format("\n%d/%d checks passed", total - failures, total))

if failures > 0 then
	error(string.format("%d test failure(s)", failures), 0)
end
