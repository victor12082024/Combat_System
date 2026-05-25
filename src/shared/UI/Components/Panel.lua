--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Shared.Packages.Roact)

return function(props)
	local theme = props.theme
	return Roact.createElement("Frame", {
		Size = props.size or UDim2.fromScale(1, 1),
		Position = props.position,
		BackgroundColor3 = props.backgroundColor3 or theme.panel,
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
	}, {
		Corner = Roact.createElement("UICorner", { CornerRadius = props.cornerRadius or theme.cornerRadius }),
		Stroke = Roact.createElement("UIStroke", { Color = theme.border, Thickness = theme.strokeThickness }),
		Gradient = Roact.createElement("UIGradient", {
			Color = ColorSequence.new(theme.gradientTop, theme.gradientBottom),
			Rotation = props.gradientRotation or 90,
		}),
		Padding = Roact.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
			PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12),
		}),
		Child = props[Roact.Children],
	})
end
