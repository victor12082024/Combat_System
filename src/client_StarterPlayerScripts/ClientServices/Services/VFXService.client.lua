-- StarterPlayerScripts/ClientServices/Services/VFXService.client.lua
--[[
    VFXService (CLIENT)
    What this service is:
    - A single place to play VFX by name so your combat/move logic never spawns particles directly.
    - Supports simple "templates" stored in ReplicatedStorage and clones them into Workspace.
    - Designed to scale into:
        - pooling (reuse emitters instead of cloning)
        - per-move presets
        - quality settings / LOD
        - sound hooks

    Where VFX templates should live:
    ReplicatedStorage
      └─ Combat
         └─ VFX
            ├─ DashStreak (Folder/Model/Attachment/ParticleEmitter/etc)
            ├─ HitSpark
            └─ PowerUpAura

    How to use:
    VFXService:Play("DashStreak", character)
    VFXService:PlayAt("HitSpark", worldPosition)
    VFXService:PlayOnPart("PowerUpAura", hrp)

    Notes:
    - This is a starter implementation that works now.
    - It tries to handle common VFX types (ParticleEmitter, Beam, Trail) safely.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local CombatFolder = ReplicatedStorage:WaitForChild("Combat")
local VFXFolder = CombatFolder:WaitForChild("VFX") -- You must create this folder and store templates inside it

local VFXService = {}
VFXService.__index = VFXService

-- Default cleanup time if caller doesn't specify.
local DEFAULT_LIFETIME = 2

local function getTemplate(vfxName: string): Instance?
	local template = VFXFolder:FindFirstChild(vfxName)
	return template
end

local function getHRP(subject: Instance?): BasePart?
	if not subject then return nil end
	if subject:IsA("Model") then
		local hrp = subject:FindFirstChild("HumanoidRootPart")
		if hrp and hrp:IsA("BasePart") then
			return hrp
		end
	elseif subject:IsA("BasePart") then
		return subject
	end
	return nil
end

local function setWorldCFrame(inst: Instance, cf: CFrame)
	if inst:IsA("BasePart") then
		inst.CFrame = cf
	elseif inst:IsA("Model") then
		if inst.PrimaryPart then
			inst:PivotTo(cf)
		else
			inst:PivotTo(cf)
		end
	elseif inst:IsA("Attachment") then
		local parent = inst.Parent
		if parent and parent:IsA("BasePart") then
			parent.CFrame = cf
		end
	end
end

local function enableEmitters(root: Instance, emitCount: number?)
	-- Attempts to "burst" emitters immediately
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("ParticleEmitter") then
			d.Enabled = true
			if emitCount and emitCount > 0 then
				-- Emit is a one-shot burst independent of Enabled
				pcall(function() d:Emit(emitCount) end)
			end
		elseif d:IsA("Beam") then
			d.Enabled = true
		elseif d:IsA("Trail") then
			d.Enabled = true
		end
	end
end

local function disableEmitters(root: Instance)
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail") then
			d.Enabled = false
		end
	end
end

--=====================================================
-- Public API
--=====================================================

-- Play VFX attached to a Model or Part (defaults to HumanoidRootPart if Model).
-- opts:
--  - lifetime (number) seconds until cleanup
--  - emitCount (number) burst emitters immediately
--  - offsetCFrame (CFrame) local offset applied relative to part
function VFXService:Play(vfxName: string, subject: Instance?, opts: table?)
	opts = opts or {}

	local template = getTemplate(vfxName)
	if not template then
		warn(("[VFXService] Missing VFX template: %s"):format(vfxName))
		return nil
	end

	local part = getHRP(subject)
	if not part then
		warn(("[VFXService] Subject has no valid part/HRP for VFX: %s"):format(vfxName))
		return nil
	end

	local clone = template:Clone()
	clone.Name = vfxName

	-- Parent somewhere stable
	clone.Parent = Workspace

	-- Place it
	local offset = opts.offsetCFrame or CFrame.new()
	setWorldCFrame(clone, part.CFrame * offset)

	-- Enable/burst
	enableEmitters(clone, opts.emitCount)

	-- Cleanup
	local lifetime = opts.lifetime or DEFAULT_LIFETIME
	if lifetime > 0 then
		-- Optional: turn off continuous emitters shortly before cleanup (prevents lingering)
		task.delay(math.max(0, lifetime - 0.2), function()
			if clone and clone.Parent then
				disableEmitters(clone)
			end
		end)
		Debris:AddItem(clone, lifetime)
	end

	return clone
end

-- Play VFX at a world position (not attached)
-- opts:
--  - lifetime (number)
--  - emitCount (number)
--  - lookAt (Vector3) optional direction/orientation target
function VFXService:PlayAt(vfxName: string, position: Vector3, opts: table?)
	opts = opts or {}

	local template = getTemplate(vfxName)
	if not template then
		warn(("[VFXService] Missing VFX template: %s"):format(vfxName))
		return nil
	end

	local clone = template:Clone()
	clone.Name = vfxName
	clone.Parent = Workspace

	local cf
	if opts.lookAt then
		cf = CFrame.new(position, opts.lookAt)
	else
		cf = CFrame.new(position)
	end

	setWorldCFrame(clone, cf)
	enableEmitters(clone, opts.emitCount)

	local lifetime = opts.lifetime or DEFAULT_LIFETIME
	if lifetime > 0 then
		task.delay(math.max(0, lifetime - 0.2), function()
			if clone and clone.Parent then
				disableEmitters(clone)
			end
		end)
		Debris:AddItem(clone, lifetime)
	end

	return clone
end

-- Convenience: play on a specific part
function VFXService:PlayOnPart(vfxName: string, part: BasePart, opts: table?)
	return self:Play(vfxName, part, opts)
end

return setmetatable({}, VFXService)
