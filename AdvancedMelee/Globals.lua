local Globals = {}

Globals.Menu = {
    Tabs = {
        Aimbot = true,
        ChargeBot = false,
        Visuals = false,
        Misc = false
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
        CritRefill = {Active = true, NumCrits = 1},
        CritMode = 1,
        CritModes = {"Rage", "On Button"},
        TroldierAssist = false,
    },
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
    AttackTicks = {},
    NextAttackTime = 0,
    Weapon = nil,
    pWeaponData = nil,
    WeaponID = nil,
    WeaponDefIndex = nil,
    WeaponDef = nil,
    WeaponName = nil,
    UsingMargetGarden = false,
    SwingRange = 48,
    SwingGHullSize = 35.6,
    Can_Attack = false,
    can_charge = false,
    BlastJump = false,
    ChargeLeft = 0,
}

Globals.Players = {}

Globals.vTarget = {
    entity = nil,
    index = nil,
    GetAbsOrigin = nil,
    PredTicks = {},
    BacktrackTicks = {},
}

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

Globals.Gui = {
    IsVisible = false,
    FakeLatency = false,
    FakeLatencyAmount = 0,
    Backtrack = false,
    CritHackKey = gui.GetValue("Crit Hack Key")
}

return Globals