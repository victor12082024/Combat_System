-- ReplicatedStorage/Combat/Moves/QuickSlash.lua
-- Single-press melee hit: find closest target and apply damage (server side).

return {
	Name = "QuickSlash",

	Type = "Melee",
	TargetTag = "BadGuy",

	CooldownSeconds = 0.35,
	Damage = 12,

	Targeting = {
		MaxRange = 10,
		RequireLineOfSight = false, -- set true if you want LOS required for basic hits
	},

	Animations = {
		Slash = "QuickSlash",
	},

	Markers = {
		Hit = "Hit", -- optional if you later do marker-confirm hits
	},

	VFX = {
		Swing = "SlashTrail",
		Impact = "HitSpark",
	},
}
