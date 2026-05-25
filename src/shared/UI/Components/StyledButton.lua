--!strict
-- ReplicatedStorage/Shared/UI/Components/StyledButton.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Roact = require(ReplicatedStorage.Shared.Packages.Roact)

local StyledButton = Roact.Component:extend("StyledButton")

function StyledButton:init()
	self.buttonRef = Roact.createRef()
end

local function tween(button: TextButton, targetColor: Color3, scale: number)
	TweenService:Create(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundColor3 = targetColor,
		Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset, button.Size.Y.Scale, math.max(0, button.Size.Y.Offset + scale)),
	}):Play()
end

function StyledButton:render()
	local p = self.props
	local theme = p.theme
	local palette = theme.button
	local disabled = p.disabled == true
	local buttonColor = disabled and palette.disabled or (p.primary and palette.primary or palette.secondary)
	local textColor = disabled and palette.disabledText or palette.text

	return Roact.createElement("TextButton", {
		Text = p.text or "Button",
		Size = p.size or UDim2.fromOffset(220, 42),
		Position = p.position,
		AnchorPoint = p.anchorPoint,
		LayoutOrder = p.layoutOrder,
		BackgroundColor3 = buttonColor,
		TextColor3 = textColor,
		Font = p.font or theme.font,
		TextSize = p.textSize or 18,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		[Roact.Ref] = self.buttonRef,
		[Roact.Event.Activated] = function()
			if not disabled and p.onActivated then p.onActivated() end
		end,
		[Roact.Event.MouseEnter] = function(rbx)
			if not disabled then tween(rbx, palette.hover, 2) end
		end,
		[Roact.Event.MouseLeave] = function(rbx)
			if not disabled then tween(rbx, buttonColor, -2) end
		end,
		[Roact.Event.MouseButton1Down] = function(rbx)
			if not disabled then tween(rbx, palette.hover, -2) end
		end,
		[Roact.Event.MouseButton1Up] = function(rbx)
			if not disabled then tween(rbx, palette.hover, 2) end
		end,
	}, {
		Corner = Roact.createElement("UICorner", { CornerRadius = p.cornerRadius or theme.cornerRadius }),
		Stroke = Roact.createElement("UIStroke", { Color = theme.border, Thickness = theme.strokeThickness }),
		Padding = Roact.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
		}),
	})
end

return StyledButton
