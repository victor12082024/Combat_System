-- StarterPlayerScripts/ClientServices/Controllers/CharacterInputController.client.lua
--[[
    CharacterInputController (CLIENT)
    What this script is:
    - Always-on input adapter for character-based moves (no tool required).
    - Reads player input and forwards it to CombatController.

    Used with:
    - CombatController.client.lua (does the real work)
    - Tool-based input can still exist via each Tool's ClientAdapter.client.lua

    How to customize:
    - If you want TOOL input to override character input:
        - Add a flag in CombatController (e.g., CombatController:SetToolEquipped(true/false))
        - Or check if any tool is equipped before allowing character-based activation.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local CombatController = require(player.PlayerScripts.ClientServices.Controllers.CombatController)

-- If you later want to disable character-based R unless unarmed,
-- you can add a check here (like checking character for a Tool).
local function isToolEquipped(): boolean
	local char = player.Character
	if not char then return false end
	return char:FindFirstChildOfClass("Tool") ~= nil
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	-- Character-based activation (R)
	if input.KeyCode == Enum.KeyCode.R then
		-- If you want tool to override, uncomment this:
		-- if isToolEquipped() then return end

		CombatController:TryStartMove("ChainStrike", { source = "Character" })
		return
	end

	-- Chain steps on click
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		CombatController:TryStepMove("ChainStrike")
		return
	end
end)
