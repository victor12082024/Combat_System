-- Rs/Combat/Utils/Targeting.lua
--[[
    Targeting.lua  SHARED TARGETING HELPERS (Client + Server)

    What this is:
    - reusable helper for selecting targets using CollectionService tags
    - Support cases where the tag is on:
        - enemy model
    
    Main Function:
    - GetClosestTaggedTarget(tagName, originPos, opts) -> Model | nil

    Options (opts):
    - maxRange (number) default 60
    - requireLOS (boolean) default false
    - avoidModel (Model?) optional - tries to avoid selecting this one
    - ignoreList (table<Instance>) optional - raycast exclusions
    - sortSecondary (function(model)->number) optional - tie-breaker (rare)
]]

local cs = game:GetService("CollectionService")
local ws = game:GetService("Workspace")

local Targeting = {}

-- ------- small helpers ---------

local function resolveModel(inst: Instance?): Model?
    if not inst then return nil end
    if inst:IsA("Model") then
        return inst
    end
    return inst:FindFirstAncestorOfClass("Model")
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

local function hasLOS(originPos: Vector3, targetModel: Model, ignoreList: {Instance}?): boolean
    local hrp = getHRP(targetModel)
    if not hrp then return false end

    local dir = hrp.Position - originPos
    local dist = dir.Magnitude
    if dist < 0.05 then
        return true
    end
    
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    params.FilterDescendantsInstances = ignoreList or {}

    local result = ws:Raycast(originPos, dir, params)
    if not result then
        -- nothing in the way
        return true
    end

    -- visible if we hit something within the target model
    return result.Instance ~= nil and result.Instance:IsDescendantOf(targetModel)
end

-- ----------- main API ----------

-- returns the closest valid target Model with given tag or nil
function Targeting:GetClosestTaggedTarget(tagName: string, originPos: Vector3, opts: table?)
    opts = opts or {}

    local maxRange = opts.maxRange or 60
    local requireLOS = opts.requireLOS == true
    local avoidModel = opts.avoidModel
    local ignoreList = opts.ignoreList or {}
    local sortSecondary = opts.sortSecondary -- optional tie breaker

    local taggedInstances = cs:GetTagged(tagName)

    local bestModel: Model? = nil
    local bestDist = math.huge
    local bestSecondary = math.huge

    for _, inst in ipairs(taggedInstances) do
        local model = resolveModel(inst)
        if model and model ~= avoidModel and isAlive(model) then
            local hrp = getHRP(model)
            if hrp then
                local dist = (hrp.Position - originPos).Magnitude
                if dist <= maxRange then
                    if (not requireLOS) or hasLOS(originPos, model, ignoreList) then
                        if dist < bestDist then
                            bestDist = dist
                            bestModel = model
                            bestSecondary = sortSecondary and sortSecondary(model) or math.huge
                        elseif dist == bestDist and sortSecondary then
                            local sec = sortSecondary(model)
                            if sec < bestSecondary then
                                bestSecondary = sec
                                bestModel = model
                            end
                        end
                    end
                end
            end
        end
    end

    -- if we avoid the last target and found nothing then fall back to allow it
    if not bestModel and avoidModel then
        return Targeting:GetClosestTaggedTarget(tagName, originPos, {
            maxRange = maxRange,
            requireLOS = requireLOS,
            avoidModel = nil,
            ignoreList = ignoreList,
            sortSecondary = sortSecondary,
        })
    end

    return bestModel
end

-- direct LOS check
function Targeting:hasLOS(originPos, targetModelOrInstance, ignoreList)
    local model = resolveModel(targetModelOrInstance)
    if not model then return false end
    return hasLOS(originPos, model, ignoreList)
end

-- checks if something is a valid target with the tag + alive + HRP
function Targeting:IsValidTaggedTarget(tagName, targetModelOrInstance): boolean
    local model = resolveModel(targetModelOrInstance)
    if not model then return false end

    -- extensive Collection tag retrieval
    if cs:HasTag(model, tagName) then
        return isAlive(model) and getHRP(model) ~= nil
    end

    for _, inst in ipairs(cs:GetTagged(tagName)) do
        if resolveModel(inst) == model then
            return isAlive(model) and getHRP(model) ~= nil
        end
    end

    return false
end

return Targeting