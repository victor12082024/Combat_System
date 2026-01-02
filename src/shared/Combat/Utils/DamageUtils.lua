-- ReplicatedStorage/Combat/Shared/DamageUtils.lua
--[[
	DamageUtils
	What this module is:
	- A small utility layer for damage calculations and applying damage safely.

	Why you will need this later:
	- Damage will stop being "humanoid:TakeDamage(baseDamage)" pretty quickly.
	- You’ll want:
		- Crit chance / crit multiplier
		- Damage types (slash, fire, blunt)
		- Armor / resistances
		- Distance falloff (ranged attacks)
		- Headshots / weakpoints
		- Friendly fire rules

	How it’s structured:
	- ComputeDamage(...) returns a number (final damage)
	- ApplyDamage(...) applies it to a humanoid safely

	Starter-friendly:
	- Defaults do nothing fancy unless opts specify it.
]]

local DamageUtils = {}

local function clamp(n: number, a: number, b: number): number
	if n < a then return a end
	if n > b then return b end
	return n
end

local function getHumanoid(model: Model?): Humanoid?
	if not model then return nil end
	return model:FindFirstChildOfClass("Humanoid")
end

-- Computes a final damage number using optional modifiers.
-- baseDamage: number
-- opts can include:
--   critChance (0..1), critMultiplier (>=1)
--   flatBonus (number), multiplier (number)
--   falloff: { startDist: number, endDist: number, minMultiplier: number }
--   distance: number (used with falloff)
function DamageUtils:ComputeDamage(baseDamage: number, opts: table?): number
	opts = opts or {}

	local dmg = math.max(0, baseDamage or 0)

	-- flat bonus
	if typeof(opts.flatBonus) == "number" then
		dmg += opts.flatBonus
	end

	-- global multiplier
	if typeof(opts.multiplier) == "number" then
		dmg *= opts.multiplier
	end

	-- distance falloff (useful for ranged / shockwaves)
	if opts.falloff and typeof(opts.distance) == "number" then
		local f = opts.falloff
		local d = opts.distance

		local startDist = f.startDist or 0
		local endDist = f.endDist or startDist
		local minMult = clamp(f.minMultiplier or 1, 0, 1)

		if d <= startDist then
			-- no falloff yet
		elseif d >= endDist then
			dmg *= minMult
		else
			local t = (d - startDist) / math.max(0.001, (endDist - startDist))
			local mult = (1 - t) + (minMult * t)
			dmg *= mult
		end
	end

	-- crit
	local critChance = clamp(opts.critChance or 0, 0, 1)
	local critMult = math.max(1, opts.critMultiplier or 1.5)

	if critChance > 0 then
		if math.random() < critChance then
			dmg *= critMult
			opts.didCrit = true -- optional breadcrumb
		end
	end

	return math.floor(dmg + 0.5)
end

-- Applies damage to a target model safely.
-- Returns: (didApply: boolean, finalDamage: number)
function DamageUtils:ApplyDamage(attacker: Player?, targetModel: Model, baseDamage: number, opts: table?): (boolean, number)
	if not targetModel or not targetModel:IsA("Model") then
		return false, 0
	end

	local hum = getHumanoid(targetModel)
	if not hum or hum.Health <= 0 then
		return false, 0
	end

	local final = self:ComputeDamage(baseDamage, opts)
	if final <= 0 then
		return false, 0
	end

	hum:TakeDamage(final)
	return true, final
end

return DamageUtils
