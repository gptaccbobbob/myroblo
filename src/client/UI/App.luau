--!nonstrict
-- Root UI component. Subscribes to server remotes, owns app-level state,
-- and renders CurrencyDisplay + NotificationToast.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local Remotes = require(ReplicatedStorage.Shared.Network.Remotes)

local CurrencyDisplay = require(script.Parent.CurrencyDisplay)
local NotificationToast = require(script.Parent.NotificationToast)

local NOTIFICATION_TTL_SECONDS = 3

local App = Roact.Component:extend("App")

function App:init()
	self:setState({
		cash = 0,
		notifications = {},
	})
	self._nextNotifId = 0
	self._connections = {}
end

function App:didMount()
	table.insert(
		self._connections,
		Remotes.CashChanged.OnClientEvent:Connect(function(cash)
			self:setState({ cash = cash })
		end)
	)

	table.insert(
		self._connections,
		Remotes.Notify.OnClientEvent:Connect(function(message, kind)
			self._nextNotifId += 1
			local id = self._nextNotifId

			self:setState(function(state)
				local list = table.clone(state.notifications)
				table.insert(list, { id = id, message = message, kind = kind })
				return { notifications = list }
			end)

			task.delay(NOTIFICATION_TTL_SECONDS, function()
				self:setState(function(state)
					local kept = {}
					for _, n in state.notifications do
						if n.id ~= id then
							table.insert(kept, n)
						end
					end
					return { notifications = kept }
				end)
			end)
		end)
	)
end

function App:willUnmount()
	for _, conn in self._connections do
		conn:Disconnect()
	end
	self._connections = {}
end

function App:render()
	return Roact.createElement("ScreenGui", {
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, {
		Currency = Roact.createElement(CurrencyDisplay, {
			cash = self.state.cash,
		}),
		Notifications = Roact.createElement(NotificationToast, {
			items = self.state.notifications,
		}),
	})
end

return App
