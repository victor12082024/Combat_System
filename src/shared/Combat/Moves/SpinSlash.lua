-- ReplicatedStorage/Combat/Moves/SpinSlash.lua
-- Single-press AOE: damage all tagged targets in radius around attacker (server side).

return {
	Name = "SpinSlash",

	Type = "AOE",
	TargetTag = "BadGuy",

	CooldownSeconds = 4,
	Damage = 18,

	AOE = {
		Radius = 10,
	},

	Animations = {
		Spin = "SpinSlash",
	},

	Markers = {
		Hit = "Hit", -- optional later
	},

	VFX = {
		Spin = "SpinRing",
		Impact = "HitSpark",
	},
}
