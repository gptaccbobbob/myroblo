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
local function buildPlotForPlayer(player: Player, plotIndex: number): Model
	local plot = Instance.new("Model")
	plot.Name = "Tycoon_" .. player.UserId
	plot:SetAttribute("OwnerId", player.UserId)

	local origin = Vector3.new(plotIndex * PLOT_SPACING, 5, 0)

	local floor = makePart("Floor", Vector3.new(40, 1, 40), origin, BrickColor.new("Really black"))
	floor.Material = Enum.Material.WoodPlanks
	floor.Parent = plot

	local nameSign = Instance.new("Part")
	nameSign.Name = "NameSign"
	nameSign.Size = Vector3.new(8, 2, 0.5)
	nameSign.Position = origin + Vector3.new(0, 8, -20)
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

	local dropper = makePart(
		"Dropper",
		Vector3.new(4, 4, 4),
		origin + Vector3.new(-15, 5, 0),
		BrickColor.new("Bright yellow")
	)
	dropper:SetAttribute("ItemId", "starter_dropper")
	CollectionService:AddTag(dropper, "Dropper")
	dropper.Parent = plot

	local collector = makePart(
		"Collector",
		Vector3.new(6, 1, 6),
		origin + Vector3.new(15, 0.5, 0),
		BrickColor.new("Bright green")
	)
	collector.Material = Enum.Material.Neon
	CollectionService:AddTag(collector, "Collector")
	collector.Parent = plot

	-- A simple ramp so drops slide from dropper to collector.
	local conveyor = makePart(
		"Conveyor",
		Vector3.new(28, 0.5, 4),
		origin + Vector3.new(0, 2, 0),
		BrickColor.new("Medium stone grey")
	)
	conveyor.CFrame = conveyor.CFrame * CFrame.Angles(0, 0, math.rad(-3))
	conveyor.Parent = plot

	-- One example BuyButton — buys the iron dropper and replaces the starter.
	local buyButton = makePart(
		"BuyButton_IronDropper",
		Vector3.new(4, 1, 4),
		origin + Vector3.new(-15, 0.5, 12),
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
	local origin = Vector3.new(plotIndex * PLOT_SPACING, 10, 20)
	local character = player.Character or player.CharacterAdded:Wait()
	local hrp = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	if hrp then
		hrp.CFrame = CFrame.new(origin)
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
