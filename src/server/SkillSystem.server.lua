local replicatedStorage = game:GetService("ReplicatedStorage")
local debris = game:GetService("Debris")

local skillRemote = Instance.new("RemoteEvent")
skillRemote.Name = "SkillRemoteRE"
skillRemote.Parent = replicatedStorage

local function attachVFXToHand(bodyPart, yOffset, lifetime, character)
    if not bodyPart then return end

    local vfx = workspace:WaitForChild("ForceField"):Clone()        -- this is the vfx part
    vfx.Anchored = false
    vfx.CanCollide = false
    vfx.CFrame = bodyPart.CFrame * CFrame.new(0, yOffset, 0)
    vfx.Parent = character

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = bodyPart
    weld.Part1 = vfx
    weld.Parent = vfx

    debris:AddItem(vfx, lifetime)
end

--    rbxassetid://14197316125

skillRemote.OnServerEvent:Connect(function(player)
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then return end
	
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end
	
	local rightHand = character:FindFirstChild("RightHand")
    local leftHand = character:FindFirstChild("LeftHand")
    local lowerTorso = character:FindFirstChild("LowerTorso")
	local defaultWalkSpeed = humanoid.WalkSpeed
	humanoid.WalkSpeed = 0
	
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://97054608555392"	-- put your animation id here
	
	local animTrack = animator:LoadAnimation(anim)
	
    local didHit = false
	
	
    animTrack:GetMarkerReachedSignal("Start"):Connect(function()
        attachVFXToHand(lowerTorso, -1.5, 2.5, character)
    end)
	
    animTrack:GetMarkerReachedSignal("HitMarker"):Connect(function()
        if didHit then return end
        didHit = true

        local hitbox = workspace:FindFirstChild("Hitbox"):Clone()          -- this is the part to make hit box area for attack
	    hitbox.Anchored = true
	    hitbox.CanCollide = false
	    hitbox.CFrame = rootPart.CFrame * CFrame.new(0,0,0)
	    hitbox.Parent = workspace
	
	    debris:AddItem(hitbox, 0.5)
	
	    local hitOnce = {}

        local touchConn = hitbox.Touched:Connect(function(hit)
		    local enemyChar = hit:FindFirstAncestorOfClass("Model")
		    if enemyChar == character then return end
		    if hitOnce[enemyChar] then return end
		
		    local enemyHumanoid = enemyChar:FindFirstChildOfClass("Humanoid")
		    local enemyRootPart = enemyChar:FindFirstChild("HumanoidRootPart")
		
		    hitOnce[enemyChar] = true
		
		    enemyHumanoid:TakeDamage(40)
		
		    local knockback = (enemyRootPart.Position - rootPart.Position).Unit
		    enemyRootPart.Velocity = knockback * 300 + Vector3.new(0, 100, 0)
	    end)

        task.delay(0.55, function()
            if touchConn then touchConn:Disconnect() end
        end)

        attachVFXToHand(leftHand, -0.5, 0.5, character)
    end)

    animTrack:Play()

    animTrack.Stopped:Connect(function()
        if humanoid then
            humanoid.WalkSpeed = defaultWalkSpeed
        end
    end)
end)