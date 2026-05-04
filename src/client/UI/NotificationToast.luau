--!nonstrict
-- Stack of transient toasts in the top-right of the screen.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)

local KIND_COLORS = {
	info = Color3.fromRGB(60, 130, 200),
	success = Color3.fromRGB(60, 170, 80),
	error = Color3.fromRGB(200, 60, 60),
}

local function NotificationToast(props)
	local items = props.items or {}

	local children = {
		Layout = Roact.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
		}),
	}

	for index, notif in items do
		children["Notif_" .. tostring(notif.id)] = Roact.createElement("Frame", {
			LayoutOrder = index,
			Size = UDim2.new(0, 300, 0, 50),
			BackgroundColor3 = KIND_COLORS[notif.kind] or KIND_COLORS.info,
			BorderSizePixel = 0,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 6),
			}),
			Padding = Roact.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
				PaddingTop = UDim.new(0, 6),
				PaddingBottom = UDim.new(0, 6),
			}),
			Label = Roact.createElement("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = notif.message,
				TextColor3 = Color3.new(1, 1, 1),
				Font = Enum.Font.GothamMedium,
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
		})
	end

	return Roact.createElement("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 16),
		Size = UDim2.new(0, 320, 1, -32),
		BackgroundTransparency = 1,
	}, children)
end

return NotificationToast
