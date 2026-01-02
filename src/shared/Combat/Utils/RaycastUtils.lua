-- ReplicatedStorage/Combat/Shared/RaycastUtils.lua
--[[
	RaycastUtils
	What this module is:
	- A small collection of reusable raycast helpers used across combat + movement.

	What you will use this for later:
	- Line of Sight checks (player ↔ enemy)
	- Safe landing checks for hybrid dash/teleports
	- Ground snapping (placing VFX on the ground, landing logic)
	- Projectile / melee raycasts with consistent filtering

	Design goals:
	- Easy to read.
	- One “good” place to standardize RaycastParams creation.
	- No combat-specific assumptions (works for AI too).
]]

local Workspace = game:GetService("Workspace")

local RaycastUtils = {}

-- Creates RaycastParams with a consistent filter.
-- filterDescendants: array of Instances to ignore (commonly { attackerCharacter })
function RaycastUtils:MakeParams(filterDescendants: {Instance}?, ignoreWater: boolean?): RaycastParams
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = filterDescendants or {}
	params.IgnoreWater = (ignoreWater ~= false) -- default true
	return params
end

-- Basic raycast wrapper.
function RaycastUtils:Raycast(origin: Vector3, direction: Vector3, ignoreList: {Instance}?): RaycastResult?
	local params = self:MakeParams(ignoreList, true)
	return Workspace:Raycast(origin, direction, params)
end

-- True if there is a clear line of sight to the target model.
-- It is considered visible if the ray hits *any descendant* of the target model, or nothing at all.
function RaycastUtils:HasLineOfSight(fromPos: Vector3, targetModel: Model, ignoreList: {Instance}?): boolean
	local hrp = targetModel:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end

	local dir = hrp.Position - fromPos
	local dist = dir.Magnitude
	if dist <= 0.05 then
		return true
	end

	local result = self:Raycast(fromPos, dir, ignoreList)
	if not result then
		return true
	end

	return result.Instance and result.Instance:IsDescendantOf(targetModel)
end

-- Finds the ground position directly below a point.
-- Returns (hitPosition, hitNormal, hitInstance) or nil if nothing hit.
function RaycastUtils:RaycastDown(point: Vector3, maxDistance: number, ignoreList: {Instance}?): (Vector3?, Vector3?, Instance?)
	local dir = Vector3.new(0, -math.abs(maxDistance), 0)
	local result = self:Raycast(point, dir, ignoreList)
	if not result then return nil end
	return result.Position, result.Normal, result.Instance
end

-- Attempts to adjust a desired landing position away from walls/obstacles.
-- This is useful for “hybrid dash” teleports where you want reliability + fewer clips.
--
-- How it works:
-- - Raycast from anchorPoint toward desiredPos
-- - If blocked, push landing out slightly along the surface normal
--
-- Returns a safe-ish position (still not perfect, but strong starter utility).
function RaycastUtils:AdjustLanding(anchorPoint: Vector3, desiredPos: Vector3, ignoreList: {Instance}?, pushOut: number?): Vector3
	pushOut = pushOut or 1.5

	local dir = desiredPos - anchorPoint
	if dir.Magnitude <= 0.05 then
		return desiredPos
	end

	local result = self:Raycast(anchorPoint, dir, ignoreList)
	if not result then
		return desiredPos
	end

	-- If we hit something, push away from the hit surface a bit
	return result.Position + (result.Normal * pushOut)
end

return RaycastUtils
