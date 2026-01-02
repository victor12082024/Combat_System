-- tools/Katana/ClientAdapter.client.lua
--[[
    Katana ClientAdapter (CLIENT, inside the Tool)
    What this script is:
    - Tool-based input adapter. ONLY listens while the tool is equipped.
    - Forwards input to CombatController:
        - R activates ChainStrike
        - Mouse1 triggers ChainStrike steps (during active window)

    Why this exists:
    - Keeps tool-specific input close to the tool, but keeps ALL combat logic in CombatController.
    - Makes it easy to add more tools:
        - Copy this script into the next tool and change move names if needed.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local tool = script.Parent

local CombatController = require(player.PlayerScripts.ClientServices.Controllers.CombatController)

local conns = {}

local function disconnectAll()
	for _, c in ipairs(conns) do
		c:Disconnect()
	end
	table.clear(conns)
end

tool.Equipped:Connect(function()
	disconnectAll()

	table.insert(conns, UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		-- Activate chain (R)
		if input.KeyCode == Enum.KeyCode.R then
			CombatController:TryStartMove("ChainStrike", {
				source = "Tool",
				toolName = tool.Name,
			})
			return
		end

		-- Step chain (Mouse1)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			CombatController:TryStepMove("ChainStrike")
			return
		end
	end))
end)

tool.Unequipped:Connect(function()
	disconnectAll()
end)
