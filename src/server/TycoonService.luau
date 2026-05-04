--!strict
-- Spawns a per-player tycoon plot and wires up CollectionService listeners
-- for Dropper / Collector / BuyButton tags.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local PlayerDataService = require(script.Parent.PlayerDataService)
local Dropper = require(script.Parent.Tycoon.Dropper)
local Collector = require(script.Parent.Tycoon.Collector)
local BuyButton = require(script.Parent.Tycoon.BuyButton)

local PLOT_SPACING = 200

local plotIndexByPlayer: { [Player]: number } = {}
local nextPlotIndex = 0

local TycoonService = {}

local function getOrCreateTycoonsFolder(): Folder
	local existing = Workspace:FindFirstChild("Tycoons")
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = "Tycoons"
	folder.Parent = Workspace
	return folder
end

local LOW_FRICTION = PhysicalProperties.new(0.7, 0.05, 0.1)
local SLOPE_DEGREES = 8

local function makePart(name: string, size: Vector3, position: Vector3, color: BrickColor): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.BrickColor = color
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

-- Generates a basic plot for the player so the game has something visible
-- out of the box. Once you build a custom plot template (see README), this
-- function can be replaced with a clone of that template.
--
-- Plot layout (top-down, units = studs):
--
--                        z = -19  ┌──────────┐
--                                 │ NameSign │
--                                 └──────────┘
--      x = -13         x = 0            x = 17
--    ┌─────────┐                       ┌──────────┐
--    │ Dropper │                       │ Collector│
--    └────┬────┘                       └──────────┘
--         ▼
--   ╔════════════════════════════════╗
--   ║  Conveyor (sloped down -8°)    ║
--   ╚════════════════════════════════╝
--
--    ┌─────────┐
--    │BuyButton│  z = +12
--    └─────────┘
--
local function buildPlotForPlayer(player: Player, plotIndex: number): Model
	local plot = Instance.new("Model")
	plot.Name = "Tycoon_" .. player.UserId
	plot:SetAttribute("OwnerId", player.UserId)

	-- Plot origin is at floor level (y=0). Everything is built on top.
	local origin = Vector3.new(plotIndex * PLOT_SPACING, 0, 0)

	local floor = makePart("Floor", Vector3.new(40, 1, 40), origin, BrickColor.new("Really black"))
	floor.Material = Enum.Material.WoodPlanks
	floor.Parent = plot

	local nameSign = Instance.new("Part")
	nameSign.Name = "NameSign"
	nameSign.Size = Vector3.new(10, 3, 0.5)
	nameSign.Position = origin + Vector3.new(0, 8, -19)
	nameSign.Anchored = true
	nameSign.BrickColor = BrickColor.new("Bright blue")
	nameSign.Parent = plot
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = nameSign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = player.DisplayName .. "'s Tycoon"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui

	-- Sloped conveyor: 30 long, tilted -8° around Z so its left end (near the
	-- dropper) is high and its right end (near the collector) is low. The
	-- low friction lets drops slide under gravity.
	local conveyor = makePart(
		"Conveyor",
		Vector3.new(30, 0.5, 4),
		origin + Vector3.new(0, 4, 0),
		BrickColor.new("Medium stone grey")
	)
	conveyor.Material = Enum.Material.Metal
	conveyor.CFrame = CFrame.new(conveyor.Position) * CFrame.Angles(0, 0, math.rad(-SLOPE_DEGREES))
	conveyor.CustomPhysicalProperties = LOW_FRICTION
	conveyor.Parent = plot

	-- Dropper hangs above the high (left) end of the conveyor. Drops spawn
	-- just below the dropper's bottom face (handled in Tycoon/Dropper.luau)
	-- and fall the short remaining gap onto the conveyor.
	local dropper = makePart(
		"Dropper",
		Vector3.new(3, 4, 3),
		origin + Vector3.new(-13, 10, 0),
		BrickColor.new("Bright yellow")
	)
	dropper.Material = Enum.Material.Neon
	dropper:SetAttribute("ItemId", "starter_dropper")
	CollectionService:AddTag(dropper, "Dropper")
	dropper.Parent = plot

	-- Collector sits at floor level, just past the low end of the conveyor.
	-- Drops slide off the conveyor and land on its top surface.
	local collector = makePart(
		"Collector",
		Vector3.new(6, 1, 4),
		origin + Vector3.new(17, 0.5, 0),
		BrickColor.new("Bright green")
	)
	collector.Material = Enum.Material.Neon
	CollectionService:AddTag(collector, "Collector")
	collector.Parent = plot

	-- One example BuyButton — buys the iron dropper. Placed on the floor
	-- away from the dropper-conveyor flow so the player walks onto it
	-- deliberately.
	local buyButton = makePart(
		"BuyButton_IronDropper",
		Vector3.new(4, 1, 4),
		origin + Vector3.new(-13, 1, 12),
		BrickColor.new("Bright red")
	)
	buyButton.Material = Enum.Material.Neon
	buyButton:SetAttribute("ItemId", "iron_dropper")
	CollectionService:AddTag(buyButton, "BuyButton")
	buyButton.Parent = plot

	plot.Parent = getOrCreateTycoonsFolder()
	return plot
end

local function teleportPlayerToPlot(player: Player, plotIndex: number)
	local spawnPos = Vector3.new(plotIndex * PLOT_SPACING, 5, 15)
	local character = player.Character or player.CharacterAdded:Wait()
	local hrp = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	if hrp then
		hrp.CFrame = CFrame.new(spawnPos)
	end
end

function TycoonService.start()
	-- These wire up tag-driven behavior; they handle parts created here AND
	-- any parts you later place in your Studio plot template.
	Dropper.start()
	Collector.start()
	BuyButton.start()

	PlayerDataService.profileLoaded:Connect(function(player: Player)
		local plotIndex = nextPlotIndex
		nextPlotIndex += 1
		plotIndexByPlayer[player] = plotIndex
		buildPlotForPlayer(player, plotIndex)
		task.spawn(teleportPlayerToPlot, player, plotIndex)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		local tycoonsFolder = getOrCreateTycoonsFolder()
		local plot = tycoonsFolder:FindFirstChild("Tycoon_" .. player.UserId)
		if plot then
			plot:Destroy()
		end
		plotIndexByPlayer[player] = nil
	end)
end

return TycoonService
