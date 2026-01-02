-- StarterPlayerScripts/ClientServices/Shared/AnimationUtils.lua
--[[
	AnimationUtils (CLIENT)
	What this module is:
	- A lightweight helper for playing animations and binding marker callbacks.
	- Designed for combat moves where you want "Hit" markers to drive damage timing.

	Why it exists:
	- Keeps animation boilerplate out of controllers/moves.
	- Centralizes marker wiring and cleanup so you don’t leak connections.

	Basic usage:
		local AnimationUtils = require(...AnimationUtils)
		local track = AnimationUtils:Play(character, animationIdOrInstance, {priority = Enum.AnimationPriority.Action})
		AnimationUtils:BindMarker(track, "Hit", function() print("hit frame") end)

	Notes:
	- This is CLIENT ONLY. Server should not be playing player animations.
]]

local AnimationUtils = {}

local function getAnimator(character: Model): Animator?
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	if not hum then return nil end
	return hum:FindFirstChildOfClass("Animator")
end

local function resolveAnimation(animationIdOrInstance: any): Animation?
	if typeof(animationIdOrInstance) == "Instance" and animationIdOrInstance:IsA("Animation") then
		return animationIdOrInstance
	end

	if type(animationIdOrInstance) == "string" then
		local anim = Instance.new("Animation")
		-- Accept "rbxassetid://123" OR "123"
		if animationIdOrInstance:find("rbxassetid://") then
			anim.AnimationId = animationIdOrInstance
		else
			anim.AnimationId = "rbxassetid://" .. animationIdOrInstance
		end
		return anim
	end

	return nil
end

-- opts:
--   fadeTime:number
--   weight:number
--   speed:number
--   looped:boolean
--   priority:Enum.AnimationPriority
function AnimationUtils:Play(character: Model, animationIdOrInstance: any, opts: table?)
	opts = opts or {}
	local animator = getAnimator(character)
	if not animator then return nil end

	local anim = resolveAnimation(animationIdOrInstance)
	if not anim then return nil end

	local track = animator:LoadAnimation(anim)

	if opts.priority then
		track.Priority = opts.priority
	end
	if opts.looped ~= nil then
		track.Looped = opts.looped
	end

	track:Play(opts.fadeTime or 0.1, opts.weight or 1, opts.speed or 1)
	return track
end

function AnimationUtils:Stop(track: AnimationTrack?, fadeTime: number?)
	if not track then return end
	track:Stop(fadeTime or 0.1)
end

-- Binds a marker and returns the RBXScriptConnection so you can disconnect if needed.
function AnimationUtils:BindMarker(track: AnimationTrack?, markerName: string, fn: (...any) -> ())
	if not track or not markerName or not fn then return nil end
	return track:GetMarkerReachedSignal(markerName):Connect(fn)
end

-- One-time marker (auto disconnects after first trigger)
function AnimationUtils:BindMarkerOnce(track: AnimationTrack?, markerName: string, fn: (...any) -> ())
	if not track or not markerName or not fn then return nil end
	local conn
	conn = track:GetMarkerReachedSignal(markerName):Connect(function(...)
		if conn then conn:Disconnect() end
		fn(...)
	end)
	return conn
end

return AnimationUtils
