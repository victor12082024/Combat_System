--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Shared.Packages.Roact)

return function(props)
	local theme = props.theme
	return Roact.createElement("Frame", {
		Size = props.size or UDim2.new(1, 0, 0, 56),
		BackgroundColor3 = theme.header,
		BorderSizePixel = 0,
	}, {
		Corner = Roact.createElement("UICorner", { CornerRadius = theme.cornerRadius }),
		Stroke = Roact.createElement("UIStroke", { Color = theme.border, Thickness = theme.strokeThickness }),
		Title = Roact.createElement("TextLabel", {
			Size = UDim2.new(1, -20, 1, 0),
			Position = UDim2.fromOffset(10, 0),
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = props.title or "Menu Header",
			Font = theme.font,
			TextColor3 = theme.text,
			TextSize = 28,
		}),
	})
end
