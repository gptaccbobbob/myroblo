--!nonstrict
-- Top-left HUD showing the player's current cash.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)

local function formatCash(amount: number): string
	-- Insert thousands separators: 12345 -> "12,345"
	local formatted = tostring(math.floor(amount))
	while true do
		local replaced
		formatted, replaced = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		if replaced == 0 then
			break
		end
	end
	return "$ " .. formatted
end

local function CurrencyDisplay(props)
	return Roact.createElement("Frame", {
		Size = UDim2.new(0, 240, 0, 64),
		Position = UDim2.new(0, 16, 0, 16),
		BackgroundColor3 = Color3.fromRGB(20, 20, 25),
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
	}, {
		Corner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 10),
		}),
		Stroke = Roact.createElement("UIStroke", {
			Color = Color3.fromRGB(255, 200, 50),
			Thickness = 2,
		}),
		Padding = Roact.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 14),
			PaddingRight = UDim.new(0, 14),
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
		}),
		Label = Roact.createElement("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = formatCash(props.cash or 0),
			TextColor3 = Color3.fromRGB(255, 220, 80),
			Font = Enum.Font.GothamBold,
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
	})
end

return CurrencyDisplay
