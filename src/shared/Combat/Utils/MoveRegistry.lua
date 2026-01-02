-- ReplicatedStorage/Combat/Shared/MoveRegistry.lua
-- Centralized move loader + cache.
-- Keeps require() calls consistent across client/server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatFolder = ReplicatedStorage:WaitForChild("Combat")
local MovesFolder = CombatFolder:WaitForChild("Moves")

local MoveRegistry = {}
local cache = {}

function MoveRegistry:Get(moveName: string): table
	if cache[moveName] then
		return cache[moveName]
	end

	local moveModule = MovesFolder:WaitForChild(moveName)
	local moveData = require(moveModule)

	-- Basic sanity fields so missing data fails loudly in development
	if type(moveData) ~= "table" then
		error(("Move %s did not return a table"):format(moveName))
	end
	moveData.Name = moveData.Name or moveName

	cache[moveName] = moveData
	return moveData
end

function MoveRegistry:ClearCache()
	table.clear(cache)
end

return MoveRegistry
