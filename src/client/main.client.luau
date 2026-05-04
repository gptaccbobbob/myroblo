--!nonstrict
-- Client entry. Mounts the Roact UI tree under PlayerGui.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Roact"))
local App = require(script.Parent.UI.App)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local handle = Roact.mount(Roact.createElement(App), playerGui, "TycoonRoot")

-- Hot-reload friendliness: when this script is destroyed, also tear down the UI.
script.Destroying:Connect(function()
	Roact.unmount(handle)
end)
