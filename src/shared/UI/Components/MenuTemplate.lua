--!strict
-- ReplicatedStorage/Shared/UI/Components/MenuTemplate.lua
-- Reusable root menu component: Header + Nav + Content + sample buttons.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Shared.Packages.Roact)

local Header = require(script.Parent.Header)
local Panel = require(script.Parent.Panel)
local NavButton = require(script.Parent.NavButton)
local StyledButton = require(script.Parent.StyledButton)

return function(props)
	local theme = props.theme
	local navItems = props.navItems or { "Home", "Play", "Shop", "Settings" }

	local navChildren = {
		List = Roact.createElement("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	}

	for index, item in ipairs(navItems) do
		navChildren[item] = Roact.createElement(NavButton, {
			theme = theme,
			text = item,
			selected = props.selectedNav == item,
			layoutOrder = index,
			onActivated = function()
				if props.onSelectNav then props.onSelectNav(item) end
			end,
		})
	end

	return Roact.createElement("ScreenGui", {
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, {
		Root = Roact.createElement("Frame", {
			Size = props.size or UDim2.fromScale(1, 1),
			BackgroundColor3 = theme.background,
			BorderSizePixel = 0,
		}, {
			Padding = Roact.createElement("UIPadding", {
				PaddingTop = UDim.new(0, 18), PaddingLeft = UDim.new(0, 18),
				PaddingRight = UDim.new(0, 18), PaddingBottom = UDim.new(0, 18),
			}),
			Layout = Roact.createElement("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 12) }),
			Header = Roact.createElement(Header, { theme = theme, title = props.title or theme.name }),
			Body = Roact.createElement("Frame", {
				Size = UDim2.new(1, 0, 1, -68),
				BackgroundTransparency = 1,
			}, {
				Columns = Roact.createElement("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12) }),
				Nav = Roact.createElement(Panel, {
					theme = theme,
					size = UDim2.new(0, 240, 1, 0),
					backgroundColor3 = theme.nav,
				}, navChildren),
				Content = Roact.createElement(Panel, { theme = theme, size = UDim2.new(1, -252, 1, 0) }, {
					ContentLayout = Roact.createElement("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
					Title = Roact.createElement("TextLabel", {
						Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1,
						TextXAlignment = Enum.TextXAlignment.Left, Text = props.contentTitle or "Content Panel",
						Font = theme.font, TextSize = 24, TextColor3 = theme.text, LayoutOrder = 1,
					}),
					Subtitle = Roact.createElement("TextLabel", {
						Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1,
						TextXAlignment = Enum.TextXAlignment.Left,
						Text = props.contentDescription or "Reusable menu template with animations and style presets.",
						Font = theme.font, TextSize = 16, TextColor3 = theme.subText, LayoutOrder = 2,
					}),
					Primary = Roact.createElement(StyledButton, {
						theme = theme, text = props.primaryText or "Primary Action", primary = true, layoutOrder = 3,
						onActivated = props.onPrimary,
					}),
					Secondary = Roact.createElement(StyledButton, {
						theme = theme, text = props.secondaryText or "Secondary Action", primary = false, layoutOrder = 4,
						onActivated = props.onSecondary,
					}),
					Disabled = Roact.createElement(StyledButton, {
						theme = theme, text = props.disabledText or "Disabled", disabled = true, layoutOrder = 5,
					}),
					Custom = props[Roact.Children],
				}),
			}),
		}),
	})
end
