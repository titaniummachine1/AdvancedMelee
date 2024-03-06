local Globals = {}

Globals.Menu = {
    Tabs = {
        Misc = false,
        ChargeBot = false,
        Visuals = false,
        Aimbot = true,
    },

    Aimbot = {
        Aimbot = true,
        ChargeBot = true,
        AimbotFOV = 360,
        Silent = true,
        Keybind = KEY_NONE,
        KeybindName = "Always On",
    },
    ChargeBot = {
        ChargeBot = true,
        ChargeReach = true,
        ChargeSensitivity = 50,
        ChargeControl = true,
    },
    Visuals = {
        EnableVisuals = false,
        Sphere = false,
        Section = 1,
        Sections = {"Local", "Target", "Experimental"},
        Local = {
            RangeCircle = true,
            path = {
                enable = true,
                Color = { 255, 255, 255, 255 },
                Styles = {"Pavement", "ArrowPath", "Arrows", "L Line" , "dashed", "line"},
                Style = 1,
                width = 5,
            },
        },
        Target = {
            path = {
                enable = true,
                Color = { 255, 255, 255, 255 },
                Styles = {"Pavement", "ArrowPath", "Arrows", "L Line" , "dashed", "line"},
                Style = 1,
                width = 5,
            },
        },
    },
    Misc = {
        AdvancedHitreg = true,
        CritRefill = {Active = true, NumCrits = 1},
        CritMode = 1,
        CritModes = {"Rage", "On Button"},
        TroldierAssist = false,
    },
}

Globals.Defaults = {
    vHitbox = {Min = Vector3(-24, -24, 0), Max = Vector3(24, 24, 82)}
}

Globals.pLocal = {
    entity = nil,
    index = 1,
    team = 1,
    Class = 1,
    GetAbsOrigin = Vector3{0, 0, 0},
    OnGround = true,
    ViewAngles = EulerAngles{0, 0, 0},
    Viewheight = Vector3{0, 0, 75},
    VisPos = Vector3{0, 0, 75},
    PredTicks = {},
    NextAttackTime = 0,
    WeaponsData = {
        UsingMargetGarden = false,
        PrimaryWeapon = {
            Weapon = nil,
            WeaponData = nil,
            WeaponID = nil,
            WeaponDefIndex = nil,
            WeaponDef = nil,
            WeaponName = nil,
        },
        MeleeWeapon = {
            Weapon = nil,
            WeaponData = nil,
            WeaponID = nil,
            WeaponDefIndex = nil,
            WeaponDef = nil,
            WeaponName = nil,
            SwingData = {
                SmackDelay = 13,
                SwingRange = 48,
                SwingHullSize = 35.6,
                SwingHull = {Max = Vector3(17.8,17.8,17.8), Min = Vector3(-17.8,-17.8,-17.8)},
                TotalSwingRange = 48 + (35.6 / 2),
            },
        },
        Weapon = {
            Weapon = nil,
            WeaponData = nil,
            WeaponID = nil,
            WeaponDefIndex = nil,
            WeaponDef = nil,
            WeaponName = nil,
            SwingData = {
                SmackDelay = 13,
                SwingRange = 48,
                SwingHullSize = 35.6,
                SwingHull = {Max = Vector3(17.8,17.8,17.8), Min = Vector3(-17.8,-17.8,-17.8)},
                TotalSwingRange = 48 + (35.6 / 2),
            },
        },
    },
    Actions = {
        CanSwing = false,
        Attacked = false,
        NextAttackTime = 0,
        NextAttackTime2 = 0,
        LastAttackTime = 0,
        TicksBeforeHit = 0,
        CanCharge = false,
    },
    BlastJump = false,
    ChargeLeft = 0,
    vHitbox = {Min = Vector3(-24, -24, 0), Max = Vector3(24, 24, 82)}
}

Globals.Players = {}

Globals.ShouldFindTarget = false

Globals.vTarget = {
    entity = nil,
    index = nil,
    GetAbsOrigin = nil,
    PredTicks = {},
    BacktrackTicks = {},
    AttackTicks = {},
    vHitbox = {Min = Vector3(-24, -24, 0), Max = Vector3(24, 24, 82)}
}

function Globals.ResetTarget()
    Globals.vTarget = {
        entity = nil,
        index = nil,
        GetAbsOrigin = nil,
        PredTicks = {},
        BacktrackTicks = {},
        AttackTicks = {},
        vHitbox = {Min = Vector3(-24, -24, 0), Max = Vector3(24, 24, 82)}
    }
end

Globals.StrafeData = {
    Strafe = false,
    lastAngles = {}, ---@type table<number, Vector3>
    lastDeltas = {}, ---@type table<number, number>
    avgDeltas = {}, ---@type table<number, number>
    strafeAngles = {}, ---@type table<number, number>
    inaccuracy = {}, ---@type table<number, number>
    pastPositions = {}, -- Stores past positions of the local player
    maxPositions = 4, -- Number of past positions to consider
}

Globals.World = {
    Gravity = 800,
    StepHeight = 18,
    Lerp = 0,
    Latency = 0,
    LatIn = 0,
    Lat_out = 0,
}

Globals.Visuals = {
    SphereCache = {},
}

Globals.Gui = {
    IsVisible = false,
    FakeLatency = false,
    FakeLatencyAmount = 0,
    Backtrack = false,
    CritHackKey = gui.GetValue("Crit Hack Key")
}

return Globals