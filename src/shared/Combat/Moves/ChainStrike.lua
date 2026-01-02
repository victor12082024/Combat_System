-- Rs/Combat/Moves/ChainStrike.lua
--[[
    ChainStrike (Hybrid Chain Attack) - MOVE DATA ONLY

    What this is:
    - Pure config/data for the ChainStrike move ( NO gameplay logic )
    - Used by:
        - Client CombatController (chain window, click gating, local targeting + response)
        - Server CombatService (auth validation, hybrid repo, damage)

    How to expand later:
    -- Add more fields (stam cost, hitbox size, camera shake keys, sounds, ect.)
    - Create more move modules (LightSlash.lua, Uppercut.lua) w/ the same pattern.
]]

return {
    Name = "ChainStrike",

    -- enemy selection (Collection Service)
    TargetTag = "BadGuy",

    -- How the move is used
    ActivationKey = Enum.KeyCode.R, -- opt: your input adapters can use this
    WindowSeconds = 5,              -- how long clicks are accepted after actvation
    MinClickInterval = 0.2,         -- min time between steps (anti spam)
    CooldownSeconds = 12,

    -- Targeting rules
    Targeting = {
        MaxRange = 60,      -- how far you can chain enemies
        ReqLOS = true,      -- raycast LOS check
        AvoidLastTarget = true,    -- prefer a diff target if possible
    },

    -- Hybrid movement ( visual dash + reliable tp )
    Hybrid = {
        AttackOffsetStuds = 4,  -- where attacker lands from target (server uses this info)
        DashFXDuration = 0.12,  -- purely visual (client uses this info)
    },

    -- Combat numbers
    Damage = 25,

    -- Animation names used ( another script grabs the name to get the id else where)
    Animations = {
        PowerUp = "ChainPowerUp",
        Slash = "ChainSlash",
    },

    -- Animation markers
    Markers = {
        Hit = "Hit",
        -- Teleport = "Teleport", 
    },

    -- VFX names used ( same as Animations )
    VFX = {
        PowerUp = "PowerUpAura",
        Dash = "DashStreak",
        Impact = "HitSpark",
    },

    -- Sound names used ( same as Others )
    SFX = {
        PowerUp = "ChainPowerUpSFX",
        Dash = "ChainDashSFX",
        Hit = "ChainHitSFX",
    }
}