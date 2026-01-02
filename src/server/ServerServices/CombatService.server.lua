-- ServerScriptService/ServerServices/CombatService.server.lua
--[[
    CombatService (SERVER)
    What this script is:
    - Authoritative server-side handler for combat moves (starting with ChainStrike).
    - Validates:
        - move window active
        - cooldown
        - target validity (CollectionService tag "BadGuy")
        - range + optional LOS
    - Executes HYBRID movement:
        - client plays dash VFX instantly
        - server reliably repositions attacker to an offset near target (teleport reliability)
    - Applies damage on a small delay (starter version).
      Later upgrade: marker-based HitConfirm remote for perfect sync + anti-exploit.

    Depends on:
    - ReplicatedStorage/Combat/Moves/ChainStrike.lua (data)
    - ReplicatedStorage/Combat/Shared/Targeting.lua (LOS helper + tag resolution)
    - ReplicatedStorage/Combat/Remotes/*
]]

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

--// Folders
local CombatFolder = ReplicatedStorage:WaitForChild("Combat")
local MovesFolder = CombatFolder:WaitForChild("Moves")
local SharedFolder = CombatFolder:WaitForChild("Utils")
local RemotesFolder = CombatFolder:WaitForChild("Remotes")

--// Remotes
local MoveStartRE = RemotesFolder:WaitForChild("MoveStart")
local MoveStepRE  = RemotesFolder:WaitForChild("MoveStep")
local FXRE        = RemotesFolder:FindFirstChild("FX") -- optional

--// Shared
local Targeting = require(SharedFolder:WaitForChild("Targeting"))
local MoveRegistry = require(SharedFolder:WaitForChild("MoveRegistry"))
local Hitbox = require(SharedFolder:WaitForChild("Hitbox"))

--========================================
-- Helpers
--========================================

local function now(): number
	return os.clock()
end

local function loadMove(moveName: string)
	return require(MovesFolder:WaitForChild(moveName))
end

local function getChar(player: Player): Model?
	return player.Character
end

local function getHumanoid(model: Model?): Humanoid?
	if not model then return nil end
	return model:FindFirstChildOfClass("Humanoid")
end

local function getHRP(model: Model?): BasePart?
	if not model then return nil end
	local hrp = model:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		return hrp
	end
	return nil
end

local function isAlive(model: Model?): boolean
	local hum = getHumanoid(model)
	return hum ~= nil and hum.Health > 0
end

local function isValidBadGuyTarget(move, targetModel: Model): boolean
	if not targetModel or not targetModel:IsA("Model") then return false end
	if not CollectionService:HasTag(targetModel, move.TargetTag) then return false end
	return isAlive(targetModel) and getHRP(targetModel) ~= nil
end

-- Compute a safe-ish landing CFrame near target
local function computeAttackCFrame(attackerHRP: BasePart, targetHRP: BasePart, offsetStuds: number): CFrame
	local toTarget = (targetHRP.Position - attackerHRP.Position)
	local dir = (toTarget.Magnitude > 0.05) and toTarget.Unit or attackerHRP.CFrame.LookVector

	local desiredPos = targetHRP.Position - dir * offsetStuds

	-- Quick collision-ish adjustment: if a wall is between target and desiredPos, push outward
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { attackerHRP.Parent, targetHRP.Parent }
	params.IgnoreWater = true

	local backVec = desiredPos - targetHRP.Position
	if backVec.Magnitude > 0.05 then
		local hit = Workspace:Raycast(targetHRP.Position, backVec, params)
		if hit then
			desiredPos = hit.Position + (-backVec.Unit * 1.5)
		end
	end

	return CFrame.new(desiredPos, targetHRP.Position)
end

--========================================
-- Per-player server state
--========================================
type PlayerState = {
	activeEndTime: number,
	cooldownEndTime: number,
	lastStepTime: number,
	lastTargetModel: Model?,
}

local state: {[Player]: PlayerState} = {}

local function getState(player: Player): PlayerState
	local st = state[player]
	if not st then
		st = {
			activeEndTime = 0,
			cooldownEndTime = 0,
			lastStepTime = 0,
			lastTargetModel = nil,
		}
		state[player] = st
	end
	return st
end

Players.PlayerRemoving:Connect(function(player)
	state[player] = nil
end)

--========================================
-- Start Move (R pressed)
--========================================
MoveStartRE.OnServerEvent:Connect(function(player: Player, moveName: string, context: table?)
	if typeof(moveName) ~= "string" then return end

	local move
	local ok = pcall(function()
		move = loadMove(moveName)
	end)
	if not ok or not move then return end

	local st = getState(player)

	-- cooldown check
	if now() < st.cooldownEndTime then
		return
	end

-- =========================================================
-- SINGLE-PRESS MOVES (QuickSlash / SpinSlash)
-- =========================================================   

    if moveName == "QuickSlash" then
        -- set cooldown immediately
        st.cooldownEndTime = now() + (move.CooldownSeconds or 0)

        local char = getChar(player)
        local attackerHRP = getHRP(char)
        local attackerHum = getHumanoid(char)
        if not char or not attackerHRP or not attackerHum or attackerHum.Health <= 0 then return end

        -- pick closest visible target using your shared Targeting module
        local maxRange = (move.Targeting and move.Targeting.MaxRange) or 10
        local requireLOS = (move.Targeting and move.Targeting.RequireLineOfSight) == true

        local target = Targeting:GetClosestTaggedTarget(move.TargetTag, attackerHRP.Position, {
            maxRange = maxRange,
            requireLOS = requireLOS,
            ignoreList = { char },
        })

        if not target or not isAlive(target) then return end

        local tHum = getHumanoid(target)
        local tHRP = getHRP(target)
        if not tHum or not tHRP then return end

        -- final range sanity
        if (tHRP.Position - attackerHRP.Position).Magnitude > maxRange then return end

        -- apply damage
        tHum:TakeDamage(move.Damage or 0)

        -- optional FX
        if FXRE then
            FXRE:FireAllClients("Impact", player, moveName, tHRP.Position)
        end

        return
    end

    if moveName == "SpinSlash" then
        -- set cooldown immediately
        st.cooldownEndTime = now() + (move.CooldownSeconds or 0)

        local char = getChar(player)
        local attackerHRP = getHRP(char)
        local attackerHum = getHumanoid(char)
        if not char or not attackerHRP or not attackerHum or attackerHum.Health <= 0 then return end

        local radius = (move.AOE and move.AOE.Radius) or 10
        local targets = Hitbox:GetTargetsInRadius(move.TargetTag, attackerHRP.Position, radius)

        for _, model in ipairs(targets) do
            if model ~= char and isAlive(model) then
                local hum = getHumanoid(model)
                local hrp = getHRP(model)
                if hum then
                    hum:TakeDamage(move.Damage or 0)
                    if FXRE and hrp then
                        FXRE:FireAllClients("Impact", player, moveName, hrp.Position)
                    end
                end
            end
        end

        -- optional spin FX at player position
        if FXRE then
            FXRE:FireAllClients("Spin", player, moveName, attackerHRP.Position)
        end

        return
    end

-- =========================================================
-- WINDOW + STEP MOVES (ChainStrike style)
-- =========================================================
	-- open active window
	st.activeEndTime = now() + (move.WindowSeconds or 0)
	st.lastStepTime = 0
	st.lastTargetModel = nil

	-- OPTIONAL: start cooldown immediately on activation instead of after window ends:
	-- st.cooldownEndTime = now() + (move.CooldownSeconds or 0)

	-- replicate powerup FX so others see it (optional)
	if FXRE then
		FXRE:FireAllClients("PowerUp", player, moveName)
	end
end)

--========================================
-- Step Move (Mouse1 clicked during window)
--========================================
MoveStepRE.OnServerEvent:Connect(function(player: Player, moveName: string, targetModel: any)
	if typeof(moveName) ~= "string" then return end
	if typeof(targetModel) ~= "Instance" then return end

	local move
	local ok = pcall(function()
		move = loadMove(moveName)
	end)
	if not ok or not move then return end

	local st = getState(player)

	-- must be in active window
	if now() > st.activeEndTime then
		return
	end

	-- step gating server-side (extra safety)
	local minInterval = move.MinClickInterval or 0
	if (now() - st.lastStepTime) < minInterval then
		return
	end
	st.lastStepTime = now()

	-- attacker validation
	local char = getChar(player)
	local attackerHRP = getHRP(char)
	local attackerHum = getHumanoid(char)
	if not char or not attackerHRP or not attackerHum or attackerHum.Health <= 0 then
		return
	end

	-- resolve target model (in case they sent a part)
	local resolvedTarget = targetModel:IsA("Model") and targetModel or targetModel:FindFirstAncestorOfClass("Model")
	if not resolvedTarget then return end

	-- validate target is a BadGuy (tag might be on a part inside model, so use helper)
	if not Targeting:IsValidTaggedTarget(move.TargetTag, resolvedTarget) then
		return
	end
	if not isAlive(resolvedTarget) then return end

	local targetHRP = getHRP(resolvedTarget)
	local targetHum = getHumanoid(resolvedTarget)
	if not targetHRP or not targetHum then return end

	-- range check
	local maxRange = (move.Targeting and move.Targeting.MaxRange) or 60
	local dist = (targetHRP.Position - attackerHRP.Position).Magnitude
	if dist > maxRange then
		return
	end

	-- LOS check (server truth)
	if move.Targeting and move.Targeting.RequireLineOfSight then
		local hasLOS = Targeting:HasLineOfSight(attackerHRP.Position, resolvedTarget, { char })
		if not hasLOS then
			return
		end
	end

	-- Avoid last target if configured (server enforces preference, but doesn't hard-block)
	if move.Targeting and move.Targeting.AvoidLastTarget and st.lastTargetModel == resolvedTarget then
		-- not blocking; you can choose to block by returning here if you want.
	end
	st.lastTargetModel = resolvedTarget

	-- HYBRID: reliable reposition near target
	local offset = (move.Hybrid and move.Hybrid.AttackOffsetStuds) or 4
	local attackCF = computeAttackCFrame(attackerHRP, targetHRP, offset)
	attackerHRP.CFrame = attackCF

	-- replicate dash FX for other clients
	if FXRE then
		FXRE:FireAllClients("Dash", player, moveName, targetHRP.Position)
	end

	-- Damage: starter version uses a small delay
	local damageAmount = move.Damage or 0
	task.delay(0.12, function()
		-- Revalidate quickly at impact time
		if not player.Parent then return end
		local c = getChar(player)
		local aHRP = getHRP(c)
		local aHum = getHumanoid(c)
		if not c or not aHRP or not aHum or aHum.Health <= 0 then return end

		if not resolvedTarget.Parent then return end
		local tHum = getHumanoid(resolvedTarget)
		local tHRP = getHRP(resolvedTarget)
		if not tHum or not tHRP or tHum.Health <= 0 then return end

		-- must be close enough to count as a hit
		local hitDist = (tHRP.Position - aHRP.Position).Magnitude
		if hitDist <= (offset + 6) then
			tHum:TakeDamage(damageAmount)

			if FXRE then
				FXRE:FireAllClients("Impact", player, moveName, tHRP.Position)
			end
		end
	end)

	-- If the window is about to end, start cooldown now (simple approach)
	-- Alternative: start cooldown when window fully ends, or on activation.
	if now() + 0.01 >= st.activeEndTime then
		st.cooldownEndTime = now() + (move.CooldownSeconds or 0)
	end
end)
