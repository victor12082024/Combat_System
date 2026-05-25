--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Shared.Packages.Roact)
local StyledButton = require(script.Parent.StyledButton)

return function(props)
	local theme = props.theme
	local selected = props.selected == true
	return Roact.createElement(StyledButton, {
		theme = theme,
		text = props.text,
		onActivated = props.onActivated,
		size = props.size or UDim2.new(1, 0, 0, 40),
		primary = selected,
		disabled = props.disabled,
		layoutOrder = props.layoutOrder,
		textSize = 16,
	})
end
