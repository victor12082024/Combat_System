-- ReplicatedStorage/Combat/Shared/Hitbox.lua
-- Simple hitbox helpers built around CollectionService tags.
-- Used for AOE moves like SpinSlash (radius around player).

local CollectionService = game:GetService("CollectionService")

local Hitbox = {}

local function getModelFromInstance(inst: Instance): Model?
	if inst:IsA("Model") then
		return inst
	end
	return inst:FindFirstAncestorOfClass("Model")
end

local function isAlive(model: Model): boolean
	local hum = model:FindFirstChildOfClass("Humanoid")
	return hum ~= nil and hum.Health > 0
end

local function getHRP(model: Model): BasePart?
	return model:FindFirstChild("HumanoidRootPart")
end

-- Returns an array of Model targets in radius.
-- tagName: CollectionService tag, e.g. "BadGuy"
-- origin: Vector3 center point
-- radius: number studs
-- opts:
--   ignoreModels: {Model}? optional list to ignore (e.g. {player.Character})
function Hitbox:GetTargetsInRadius(tagName: string, origin: Vector3, radius: number, opts: table?)
	opts = opts or {}
	local ignoreModels = opts.ignoreModels or {}

	local ignoreSet = {}
	for _, m in ipairs(ignoreModels) do
		if typeof(m) == "Instance" then
			ignoreSet[m] = true
		end
	end

	local results = {}

	for _, inst in ipairs(CollectionService:GetTagged(tagName)) do
		local model = getModelFromInstance(inst)
		if model and not ignoreSet[model] and isAlive(model) then
			local hrp = getHRP(model)
			if hrp then
				local dist = (hrp.Position - origin).Magnitude
				if dist <= radius then
					table.insert(results, model)
				end
			end
		end
	end

	return results
end

return Hitbox
