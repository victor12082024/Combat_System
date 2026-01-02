-- StarterPlayerScripts/ClientServices/Controllers/CombatController.client.lua
--[[
    CombatController (CLIENT)
    What this script is:
    - Client-side "brain" for executing move flows that require input windows (like ChainStrike).
    - Holds runtime state (active move, end time, click gating, last target).
    - Talks to the server via RemoteEvents for authoritative validation + damage.
    - Calls shared Targeting.lua to pick the closest visible "BadGuy" locally for responsiveness.

    Used by:
    - CharacterInputController.client.lua (always-on character-based input)
    - Tool ClientAdapter.client.lua (tool-based input; only active when equipped)

    Notes:
    - This script is designed to scale: add more moves by adding move data modules under ReplicatedStorage/Combat/Moves.
    - VFX/Animation are stubbed so you can drop in your real VFXService + AnimationService later.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

--// Combat folders
local CombatFolder = ReplicatedStorage:WaitForChild("Combat")
local MovesFolder = CombatFolder:WaitForChild("Moves")
local SharedFolder = CombatFolder:WaitForChild("Utils")
local RemotesFolder = CombatFolder:WaitForChild("Remotes")

--// Remotes
local MoveStartRE = RemotesFolder:WaitForChild("MoveStart")
local MoveStepRE = RemotesFolder:WaitForChild("MoveStep")
local FXRE = RemotesFolder:FindFirstChild("FX") -- optional

--// Shared helpers
local Targeting = require(SharedFolder:WaitForChild("Targeting"))
local MoveRegistry = nil -- require()
local VFXService = nil -- require()
local AnimationService = nil -- require()

--=====================================================
--  OPTIONAL: Plug in your real services later
--=====================================================

-- Replace these stubs with your own services when ready:
-- local VFXService = require(player.PlayerScripts.ClientServices.Services.VFXService)
-- local AnimationService = require(player.PlayerScripts.ClientServices.Services.AnimationService)

local function PlayVFX(vfxName: string, subject: Instance?, opts: table?)
	-- Stub: keep prints so you can verify flow immediately
	-- Later: VFXService:Play(vfxName, subject, opts)
	-- print(("[VFX] %s"):format(vfxName))
end

local function PlayAnimation(animKey: string, character: Model?)
	-- Stub: return nil for now
	-- Later: return AnimationService:Play(animKey, character)
	return nil
end

--=====================================================
--  Controller
--=====================================================

local CombatController = {}

-- Active move runtime state
local active = {
	moveName = nil :: string?,
	endTime = 0 :: number,
	lastStepTime = 0 :: number,
	lastTarget = nil :: Model?,
	context = nil :: table?,
}

local function now(): number
	return os.clock()
end

local function getCharAndHRP()
	local char = player.Character
	if not char then return nil, nil end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return char, nil end
	return char, hrp
end

local function loadMove(moveName: string)
	-- NOTE: requiring modules repeatedly returns cached table anyway
	return require(MovesFolder:WaitForChild(moveName))
end

local function clearActive()
	active.moveName = nil
	active.endTime = 0
	active.lastStepTime = 0
	active.lastTarget = nil
	active.context = nil
end

local function isActive(moveName: string?): boolean
	if not active.moveName then return false end
	if moveName and active.moveName ~= moveName then return false end
	return true
end

--=====================================================
--  Public API (called by input adapters)
--=====================================================

function CombatController:IsMoveActive(moveName: string?): boolean
	return isActive(moveName)
end

function CombatController:TryStartMove(moveName: string, context: table?)
	-- Prevent starting a second move while one is active (simple rule for now)
	if active.moveName then
		return false, "MoveAlreadyActive"
	end

	local move = loadMove(moveName)
	local char, hrp = getCharAndHRP()
	if not char or not hrp then
		return false, "NoCharacter"
	end

	-- Start the local window
	active.moveName = moveName
	active.endTime = now() + (move.WindowSeconds or 0)
	active.lastStepTime = 0
	active.lastTarget = nil
	active.context = context or {}

	-- Local responsiveness
	if move.Animations and move.Animations.PowerUp then
		PlayAnimation(move.Animations.PowerUp, char)
	end
	if move.VFX and move.VFX.PowerUp then
		PlayVFX(move.VFX.PowerUp, char)
	end

	-- Tell the server (server handles cooldown + authoritative window)
	MoveStartRE:FireServer(moveName, active.context)

	-- Auto end client-side window
	task.delay(move.WindowSeconds or 0, function()
		if active.moveName == moveName and now() >= active.endTime then
			clearActive()
		end
	end)

	return true
end

function CombatController:TryStepMove(moveName: string?)
	if not isActive(moveName) then
		return false, "NotActive"
	end

	local move = loadMove(active.moveName :: string)
	local char, hrp = getCharAndHRP()
	if not char or not hrp then
		clearActive()
		return false, "NoCharacter"
	end

	-- End if window expired
	if now() >= active.endTime then
		clearActive()
		return false, "WindowEnded"
	end

	-- Click gate
	local minInterval = move.MinClickInterval or 0
	if (now() - active.lastStepTime) < minInterval then
		return false, "Gated"
	end
	active.lastStepTime = now()

	-- Find closest visible target (client-side responsiveness)
	local ignoreList = { char }
	local avoid = (move.Targeting and move.Targeting.AvoidLastTarget) and active.lastTarget or nil

	local target = Targeting:GetClosestTaggedTarget(
		move.TargetTag,
		hrp.Position,
		{
			maxRange = (move.Targeting and move.Targeting.MaxRange) or 60,
			requireLOS = (move.Targeting and move.Targeting.RequireLineOfSight) == true,
			avoidModel = avoid,
			ignoreList = ignoreList,
		}
	)

	if not target then
		return false, "NoTarget"
	end

	active.lastTarget = target

	-- Hybrid feel: play dash VFX instantly on client
	if move.VFX and move.VFX.Dash then
		PlayVFX(move.VFX.Dash, char, { duration = move.Hybrid and move.Hybrid.DashFXDuration })
	end

	-- Send step request to server (server validates + snaps you near target + applies damage)
	MoveStepRE:FireServer(active.moveName, target)

	return true
end

--=====================================================
--  Optional: Listen to FX events so other clients see stuff too
--=====================================================

if FXRE then
	FXRE.OnClientEvent:Connect(function(fxType: string, attackerPlayer: Player, moveName: string, position: Vector3?)
		-- Stub: you can route this into VFXService later
		-- Example fxType: "Dash", "Impact", "PowerUp"
		-- position might be target position for impacts, etc.
		-- print("[FX]", fxType, attackerPlayer.Name, moveName, position)
	end)
end

return CombatController
