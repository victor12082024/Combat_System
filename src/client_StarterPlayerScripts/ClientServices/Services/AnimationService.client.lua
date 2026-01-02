-- StarterPlayerScripts/ClientServices/Services/AnimationService.client.lua
--[[
    AnimationService (CLIENT)
    What this service is:
    - A single place to play animations by "key" so move logic doesn't contain animation IDs.
    - Provides:
        - Play(animKey, character, opts) -> AnimationTrack?
        - Stop(animKey, character)
        - GetAnimator(character) -> Animator?

    Where animations are defined:
    - This starter version uses a local table mapping keys -> animationId strings.
    - Later you can replace this with:
        - ReplicatedStorage animation registry module
        - per-weapon animation sets
        - character class / stance overrides

    IMPORTANT:
    - Roblox animation ids must be like: "rbxassetid://1234567890"
    - This file is safe to run even if ids aren't set yet (it will warn and return nil).
]]

local Players = game:GetService("Players")

local player = Players.LocalPlayer

local AnimationService = {}
AnimationService.__index = AnimationService

--=====================================================
-- Animation registry (EDIT THESE)
--=====================================================
-- Replace with your real IDs:
local AnimationIds = {
	ChainPowerUp = "rbxassetid://0",
	ChainSlash   = "rbxassetid://0",
}

--=====================================================
-- Helpers
--=====================================================

local function getHumanoid(character: Model?): Humanoid?
	if not character then return nil end
	return character:FindFirstChildOfClass("Humanoid")
end

function AnimationService:GetAnimator(character: Model?): Animator?
	local hum = getHumanoid(character)
	if not hum then return nil end

	local animator = hum:FindFirstChildOfClass("Animator")
	if animator then
		return animator
	end

	-- Create animator if missing
	animator = Instance.new("Animator")
	animator.Parent = hum
	return animator
end

local function makeAnimation(animationId: string): Animation
	local anim = Instance.new("Animation")
	anim.AnimationId = animationId
	return anim
end

--=====================================================
-- Public API
--=====================================================

-- opts:
--  - fadeTime (number) default 0.1
--  - weight (number) optional
--  - speed (number) default 1
--  - looped (boolean) optional
--  - priority (Enum.AnimationPriority) optional
function AnimationService:Play(animKey: string, character: Model?, opts: table?)
	opts = opts or {}

	character = character or player.Character
	if not character then
		return nil
	end

	local animator = self:GetAnimator(character)
	if not animator then
		warn("[AnimationService] No Animator available.")
		return nil
	end

	local animationId = AnimationIds[animKey]
	if not animationId or animationId == "rbxassetid://0" then
		warn(("[AnimationService] Missing/placeholder animationId for key: %s"):format(animKey))
		return nil
	end

	local anim = makeAnimation(animationId)
	local track: AnimationTrack

	local ok, err = pcall(function()
		track = animator:LoadAnimation(anim)
	end)
	if not ok or not track then
		warn(("[AnimationService] Failed to load animation %s: %s"):format(animKey, tostring(err)))
		return nil
	end

	if opts.priority then
		track.Priority = opts.priority
	end
	if opts.looped ~= nil then
		track.Looped = opts.looped
	end
	if opts.speed then
		track:AdjustSpeed(opts.speed)
	end
	if opts.weight then
		pcall(function() track:AdjustWeight(opts.weight) end)
	end

	local fadeTime = opts.fadeTime
	if fadeTime == nil then fadeTime = 0.1 end

	track:Play(fadeTime)

	return track
end

function AnimationService:Stop(animKey: string, character: Model?, fadeTime: number?)
	character = character or player.Character
	if not character then return end

	local hum = getHumanoid(character)
	if not hum then return end

	fadeTime = fadeTime or 0.1

	-- Stop any currently playing track that matches this key's id
	local animationId = AnimationIds[animKey]
	if not animationId then return end

	for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
		local anim = track.Animation
		if anim and anim.AnimationId == animationId then
			track:Stop(fadeTime)
		end
	end
end

-- Optional: allow you to set ids at runtime if you load from another module later
function AnimationService:SetAnimationId(animKey: string, animationId: string)
	AnimationIds[animKey] = animationId
end

return setmetatable({}, AnimationService)
