-- ReplicatedStorage/Combat/Shared/StatusEffectService.lua
--[[
	StatusEffectService (SHARED)
	What this module is:
	- A lightweight status effect manager that can be used server-side (authoritative)
	  and optionally mirrored client-side for UI.

	Design goals:
	- Stack-safe (multiple effects at once)
	- Duration-based
	- Easy to query (IsActive, GetStacks, GetRemaining)
	- Doesn't assume your stats system yet (you can hook in later)

	Recommended usage:
	- Server applies effects and enforces gameplay rules (movement lock, DOT).
	- Client listens (via remotes) if you want UI.

	Example:
		StatusEffectService:Add(character, "Stun", 1.5, { source = player })
		if StatusEffectService:IsActive(character, "Stun") then ...
]]

local RunService = game:GetService("RunService")

local StatusEffectService = {}

type EffectInstance = {
	name: string,
	expiresAt: number,
	stacks: number,
	data: table?,
}

-- storage: [Model] = { [effectName] = EffectInstance }
local effects: {[Model]: {[string]: EffectInstance}} = {}

local function now()
	return os.clock()
end

local function getBucket(model: Model)
	local b = effects[model]
	if not b then
		b = {}
		effects[model] = b
	end
	return b
end

-- Add/refresh an effect.
-- opts:
--   stacksDelta:number (default 1)
--   maxStacks:number (default 1)
--   data:table (optional payload)
function StatusEffectService:Add(model: Model, effectName: string, duration: number, opts: table?)
	if not model or type(effectName) ~= "string" then return end
	duration = math.max(0, duration or 0)
	opts = opts or {}

	local bucket = getBucket(model)
	local inst = bucket[effectName]

	local stacksDelta = opts.stacksDelta or 1
	local maxStacks = opts.maxStacks or 1

	if not inst then
		inst = {
			name = effectName,
			expiresAt = now() + duration,
			stacks = self:_ClampStacks(stacksDelta, maxStacks),
			data = opts.data,
		}
		bucket[effectName] = inst
	else
		-- refresh duration, add stacks
		inst.expiresAt = math.max(inst.expiresAt, now() + duration)
		inst.stacks = self:_ClampStacks(inst.stacks + stacksDelta, maxStacks)
		if opts.data ~= nil then
			inst.data = opts.data
		end
	end
end

function StatusEffectService:_ClampStacks(stacks: number, maxStacks: number)
	maxStacks = math.max(1, maxStacks or 1)
	stacks = math.floor(stacks or 1)
	if stacks < 1 then stacks = 1 end
	if stacks > maxStacks then stacks = maxStacks end
	return stacks
end

function StatusEffectService:Remove(model: Model, effectName: string)
	local bucket = effects[model]
	if not bucket then return end
	bucket[effectName] = nil
end

function StatusEffectService:ClearAll(model: Model)
	effects[model] = nil
end

function StatusEffectService:IsActive(model: Model, effectName: string): boolean
	local bucket = effects[model]
	if not bucket then return false end
	local inst = bucket[effectName]
	if not inst then return false end
	return now() < inst.expiresAt
end

function StatusEffectService:GetStacks(model: Model, effectName: string): number
	local bucket = effects[model]
	if not bucket then return 0 end
	local inst = bucket[effectName]
	if not inst then return 0 end
	if now() >= inst.expiresAt then return 0 end
	return inst.stacks or 0
end

function StatusEffectService:GetRemaining(model: Model, effectName: string): number
	local bucket = effects[model]
	if not bucket then return 0 end
	local inst = bucket[effectName]
	if not inst then return 0 end
	return math.max(0, inst.expiresAt - now())
end

function StatusEffectService:GetData(model: Model, effectName: string)
	local bucket = effects[model]
	if not bucket then return nil end
	local inst = bucket[effectName]
	if not inst or now() >= inst.expiresAt then return nil end
	return inst.data
end

-- Cleanup expired effects occasionally (server-safe, client-safe)
local accum = 0
RunService.Heartbeat:Connect(function(dt)
	accum += dt
	if accum < 1.0 then return end
	accum = 0

	for model, bucket in pairs(effects) do
		if not model.Parent then
			effects[model] = nil
		else
			for name, inst in pairs(bucket) do
				if now() >= inst.expiresAt then
					bucket[name] = nil
				end
			end
			if next(bucket) == nil then
				effects[model] = nil
			end
		end
	end
end)

return StatusEffectService
