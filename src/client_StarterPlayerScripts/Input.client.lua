local UserInputService = game:GetService("UserInputService")
local rep = game:GetService("ReplicatedStorage")
local skillRemote = rep:WaitForChild("SkillRemoteRE")

local debounce = false

UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Z and not debounce then
		debounce = true
		skillRemote:FireServer()
		task.wait(1)
		debounce = false
	end
end)