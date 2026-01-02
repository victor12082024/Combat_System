-- ReplicatedStorage/Combat/Shared/CombatMath.lua
--[[
	CombatMath (SHARED)
	What this module is:
	- A small set of math helpers commonly needed in combat.

	Why it exists:
	- Prevents every move from inventing its own damage scaling / falloff.
	- Makes balancing easier because formulas live in one place.

	Common usage:
		local CombatMath = require(...CombatMath)
		local dmg = CombatMath:ApplyCrit(baseDamage, critChance, critMult)
		local aoe = CombatMath:DistanceFalloff(dmg, dist, inner, outer)
]]

local CombatMath = {}

function CombatMath:Clamp(x: number, a: number, b: number): number
	if x < a then return a end
	if x > b then return b end
	return x
end

function CombatMath:Lerp(a: number, b: number, t: number): number
	t = self:Clamp(t, 0, 1)
	return a + (b - a) * t
end

-- Returns multiplier 1..critMult and a boolean crit flag
function CombatMath:RollCrit(critChance: number, critMult: number)
	critChance = self:Clamp(critChance or 0, 0, 1)
	critMult = math.max(1, critMult or 1.5)

	local isCrit = (math.random() < critChance)
	return (isCrit and critMult or 1), isCrit
end

function CombatMath:ApplyCrit(baseDamage: number, critChance: number, critMult: number)
	local mult = self:RollCrit(critChance, critMult)
	return math.floor((baseDamage or 0) * mult + 0.5)
end

-- Simple linear distance falloff:
-- dist <= inner => full damage
-- dist >= outer => minMult * damage
function CombatMath:DistanceFalloff(baseDamage: number, dist: number, inner: number, outer: number, minMult: number)
	baseDamage = baseDamage or 0
	minMult = self:Clamp(minMult or 0.25, 0, 1)

	if dist <= inner then return baseDamage end
	if dist >= outer then return baseDamage * minMult end

	local t = (dist - inner) / math.max(0.001, (outer - inner))
	local mult = self:Lerp(1, minMult, t)
	return baseDamage * mult
end

return CombatMath
