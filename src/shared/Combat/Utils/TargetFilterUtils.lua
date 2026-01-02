-- ReplicatedStorage/Combat/Shared/TargetFilterUtils.lua
--[[
	TargetFilterUtils (SHARED)
	What this module is:
	- Helper functions for filtering/sorting lists of target Models.

	Why it exists:
	- Your targeting rules will grow fast (avoid last target, prefer lowest health, etc.)
	- You don’t want those rules copy-pasted across moves.

	Common usage:
		local TargetFilter = require(...TargetFilterUtils)
		candidates = TargetFilter:FilterAlive(candidates)
		candidates = TargetFilter:ExcludeModels(candidates, {lastTarget})
		local best = TargetFilter:GetClosest(candidates, originPos)
]]

local TargetFilterUtils = {}

local function getHumanoid(model: Model): Humanoid?
	return model and model:FindFirstChildOfClass("Humanoid")
end

local function getHRP(model: Model): BasePart?
	return model and model:FindFirstChild("HumanoidRootPart")
end

function TargetFilterUtils:IsAlive(model: Model): boolean
	local hum = getHumanoid(model)
	return hum ~= nil and hum.Health > 0
end

function TargetFilterUtils:FilterAlive(models: {Model}): {Model}
	local out = {}
	for _, m in ipairs(models) do
		if self:IsAlive(m) and getHRP(m) then
			table.insert(out, m)
		end
	end
	return out
end

function TargetFilterUtils:ExcludeModels(models: {Model}, exclude: {Model}): {Model}
	local set = {}
	for _, m in ipairs(exclude) do
		set[m] = true
	end

	local out = {}
	for _, m in ipairs(models) do
		if not set[m] then
			table.insert(out, m)
		end
	end
	return out
end

function TargetFilterUtils:WithinRange(models: {Model}, origin: Vector3, maxRange: number): {Model}
	local out = {}
	for _, m in ipairs(models) do
		local hrp = getHRP(m)
		if hrp then
			if (hrp.Position - origin).Magnitude <= maxRange then
				table.insert(out, m)
			end
		end
	end
	return out
end

function TargetFilterUtils:GetClosest(models: {Model}, origin: Vector3): Model?
	local best, bestDist = nil, math.huge
	for _, m in ipairs(models) do
		local hrp = getHRP(m)
		if hrp then
			local d = (hrp.Position - origin).Magnitude
			if d < bestDist then
				bestDist = d
				best = m
			end
		end
	end
	return best
end

function TargetFilterUtils:GetLowestHealth(models: {Model}): Model?
	local best, bestHP = nil, math.huge
	for _, m in ipairs(models) do
		local hum = getHumanoid(m)
		if hum and hum.Health > 0 and hum.Health < bestHP then
			bestHP = hum.Health
			best = m
		end
	end
	return best
end

return TargetFilterUtils
