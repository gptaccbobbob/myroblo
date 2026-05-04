--!strict
-- Server entry point. Bootstraps services in dependency order.

local PlayerDataService = require(script.Parent.PlayerDataService)
local TycoonService = require(script.Parent.TycoonService)

PlayerDataService.start()
TycoonService.start()

print("[Server] Tycoon online.")
