--!strict
-- Player profile lifecycle on top of ProfileService.
-- Loads on join, releases on leave, exposes getters/setters and a
-- profileLoaded signal so other services can react.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Signal = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Signal"))
local ProfileService =
	require(ServerScriptService:WaitForChild("ServerPackages"):WaitForChild("ProfileService"))
local PlayerDataTemplate = require(ReplicatedStorage.Shared.Config.PlayerDataTemplate)
local Remotes = require(ReplicatedStorage.Shared.Network.Remotes)

type PlayerData = PlayerDataTemplate.PlayerData
type Profile = {
	Data: PlayerData,
	AddUserId: (self: Profile, userId: number) -> (),
	Reconcile: (self: Profile) -> (),
	ListenToRelease: (self: Profile, callback: () -> ()) -> (),
	Release: (self: Profile) -> (),
}

-- Bump the suffix to start fresh during development without colliding
-- with existing player data.
local DATA_STORE_KEY = "PlayerData_v1"
local PROFILE_KEY_PREFIX = "Player_"

local profileStore = ProfileService.GetProfileStore(DATA_STORE_KEY, PlayerDataTemplate)

-- In Studio without API access, ProfileService falls back to a "mock"
-- store so the game still runs. We don't need to do anything special.
if RunService:IsStudio() then
	print("[PlayerDataService] Studio detected — ProfileService will use a mock store.")
end

local profiles: { [Player]: Profile } = {}

local PlayerDataService = {}

PlayerDataService.profileLoaded = Signal.new()
PlayerDataService.profileReleased = Signal.new()

function PlayerDataService.getProfile(player: Player): Profile?
	return profiles[player]
end

function PlayerDataService.getCash(player: Player): number
	local profile = profiles[player]
	if not profile then
		return 0
	end
	return profile.Data.Cash
end

local function syncLeaderstats(player: Player, cash: number)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end
	local cashValue = leaderstats:FindFirstChild("Cash")
	if cashValue and cashValue:IsA("IntValue") then
		cashValue.Value = cash
	end
end

function PlayerDataService.addCash(player: Player, amount: number)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.Data.Cash += amount
	if amount > 0 then
		profile.Data.TotalEarned += amount
	end
	syncLeaderstats(player, profile.Data.Cash)
	Remotes.CashChanged:FireClient(player, profile.Data.Cash)
end

function PlayerDataService.spendCash(player: Player, amount: number): boolean
	local profile = profiles[player]
	if not profile or profile.Data.Cash < amount then
		return false
	end
	profile.Data.Cash -= amount
	syncLeaderstats(player, profile.Data.Cash)
	Remotes.CashChanged:FireClient(player, profile.Data.Cash)
	return true
end

function PlayerDataService.ownsItem(player: Player, itemId: string): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end
	return profile.Data.OwnedItems[itemId] == true
end

function PlayerDataService.unlockItem(player: Player, itemId: string)
	local profile = profiles[player]
	if not profile then
		return
	end
	if profile.Data.OwnedItems[itemId] then
		return
	end
	profile.Data.OwnedItems[itemId] = true
	Remotes.OwnedItemsChanged:FireClient(player, profile.Data.OwnedItems)
end

local function setupLeaderstats(player: Player, cash: number)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local cashValue = Instance.new("IntValue")
	cashValue.Name = "Cash"
	cashValue.Value = cash
	cashValue.Parent = leaderstats
end

local function onPlayerAdded(player: Player)
	local profile = profileStore:LoadProfileAsync(PROFILE_KEY_PREFIX .. player.UserId) :: Profile?
	if profile == nil then
		player:Kick("[PlayerDataService] Could not load profile, please rejoin.")
		return
	end

	profile:AddUserId(player.UserId) -- GDPR
	profile:Reconcile() -- fill in any new template fields
	profile:ListenToRelease(function()
		profiles[player] = nil
		PlayerDataService.profileReleased:Fire(player)
		-- Don't kick if the player already left.
		if player.Parent == Players then
			player:Kick("[PlayerDataService] Profile session ended, please rejoin.")
		end
	end)

	if not player:IsDescendantOf(Players) then
		profile:Release()
		return
	end

	profile.Data.LastJoinTime = os.time()
	profiles[player] = profile

	setupLeaderstats(player, profile.Data.Cash)

	-- Push initial state to the client.
	Remotes.CashChanged:FireClient(player, profile.Data.Cash)
	Remotes.OwnedItemsChanged:FireClient(player, profile.Data.OwnedItems)

	PlayerDataService.profileLoaded:Fire(player, profile)
end

local function onPlayerRemoving(player: Player)
	local profile = profiles[player]
	if profile then
		profile:Release()
	end
end

function PlayerDataService.start()
	-- Catch any players that joined before the script ran (e.g., script reload).
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
end

return PlayerDataService
