-- ReplicatedStorage/Combat/Shared/CooldownService.lua
--[[
	CooldownService
	What this module is:
	- A simple per-player cooldown tracker you can use on the server (and optionally client).

	What it solves:
	- Stops cooldown logic from being scattered inside CombatService, tools, skills, etc.
	- Adds support for:
		- Per-move cooldowns (e.g., "QuickSlash")
		- Shared groups (e.g., all katana moves share a cooldown group)
		- Quick checks: CanUse / Set / GetRemaining

	How to use (server):
		local Cooldowns = require(SharedFolder.CooldownService)
		if not Cooldowns:CanUse(player, "QuickSlash") then return end
		Cooldowns:Set(player, "QuickSlash", move.CooldownSeconds)

	Notes:
	- Uses os.clock() (good for cooldown timing)
	- You still keep server authoritative.
]]

local Players = game:GetService("Players")

local CooldownService = {}

-- store[player][key] = endTime
local store: {[Player]: {[string]: number}} = {}

local function now(): number
	return os.clock()
end

local function getBucket(player: Player): {[string]: number}
	local bucket = store[player]
	if not bucket then
		bucket = {}
		store[player] = bucket
	end
	return bucket
end

Players.PlayerRemoving:Connect(function(player)
	store[player] = nil
end)

-- Returns true if the cooldown for key is finished.
function CooldownService:CanUse(player: Player, key: string): boolean
	local bucket = getBucket(player)
	local t = bucket[key] or 0
	return now() >= t
end

-- Sets cooldown end time for key.
function CooldownService:Set(player: Player, key: string, seconds: number)
	local bucket = getBucket(player)
	bucket[key] = now() + math.max(0, seconds or 0)
end

-- Returns remaining cooldown time in seconds (0 if ready).
function CooldownService:GetRemaining(player: Player, key: string): number
	local bucket = getBucket(player)
	local t = bucket[key] or 0
	return math.max(0, t - now())
end

-- Optional: shared cooldown group helper.
-- Example:
--   Cooldowns:CanUseGroup(player, "Katana")
--   Cooldowns:SetGroup(player, "Katana", 0.5)
function CooldownService:CanUseGroup(player: Player, groupName: string): boolean
	return self:CanUse(player, ("group:%s"):format(groupName))
end

function CooldownService:SetGroup(player: Player, groupName: string, seconds: number)
	self:Set(player, ("group:%s"):format(groupName), seconds)
end

return CooldownService
