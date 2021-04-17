--// SERVICES
local RepStore = game:GetService("ReplicatedStorage")

--// REQUIRES
local StateMachine = require(RepStore.Network.Utility.States)
local StateSwitchFunctions = require(script.StateChangedFunctions)

--// CONSTANTS
local NULL = {}

--// VARIABLES
local States = {
    Wandering = {
        TrackSmell = "Tracking_Smell",
        TrackFootprint = "Tracking_Footprints",
        TrackSound = "Tracking_Sound",
        StalkPlayer = "Stalking",
        Discovered = "Short_Fleeing",
        Injured = "Retreating"
    },
    Tracking_Sound = {
        TrackingLost = "Wandering",
        StalkPlayer = "Stalking",
        Discovered = "Short_Fleeing",
        Injured = "Retreating"
    },
    Tracking_Footprints = {
        TrackingLost = "Wandering",
        StalkPlayer = "Stalking",
        Discovered = "Short_Fleeing",
        Injured = "Retreating"
    },
    Tracking_Smell = {
        TrackingLost = "Wandering",
        StalkPlayer = "Stalking",
        Discovered = "Short_Fleeing",
        Injured = "Retreating"
    },
    Tracking_LostPlayer = {
        TrackingLost = "Wandering",
        StalkPlayer = "Stalking",
        Discovered = "Short_Fleeing",
        Injured = "Retreating"
    },
    Stalking = {
        PlayerLost = "Tracking_LostPlayer",
        ReadyAttack = "PrepareInterceptAttack",
        Discovered = "Stalking_Discovered",
        Injured = "Retreating"
    },
    Stalking_Discovered = {
        EngageCombat = "AcquiringTarget",
        Flee = "Short_Fleeing",
        Injured = "Retreating"
    },
    PrepareInterceptAttack = {
        EngageCombat = "InitialAttack",
        Discovered = "InitialAttack",
        Injured = "Retreating"
    },
    InitialAttack = {
        FleeCombat = "Short_Fleeing",
        FixNextTarget = "AcquiringTarget",
        Injured = "Retreating"
    },
    AcquiringTarget = {
        Attack = "Attacking",
        FleeCombat = "Short_Fleeing",
        Injured = "Retreating"
    },
    Attacking = {
        FixNextTarget = "AcquiringTarget",
        FleeCombat = "Short_Fleeing",
        injured = "Retreating"
    },
    Short_Fleeing = {
        Injured = "Retreating",
        FinishFlee = "Wandering"
    },
    Retreating = {
        BeginCooldown = "Injury_Cooldown"
    },
    Injury_Cooldown = {
        FinishCooldown = "Wandering"
    }
}

--// CONSTRUCTOR
local Handler = {}
Handler.__index = Handler

local function DefaultValues()
    return {

    }
end

function Handler.new(Data)
    Data = Data or {}
    local Obj = {}
    
    setmetatable(Obj,Handler)

    for i,v in pairs(DefaultValues()) do
        Obj[i] = Data[i] == nil and v or Data[i]
        if Obj[i] == NULL then error("Missing data for GameManager constructor:",i) end
    end

    --// INITIALIZATION
    Obj.GameStateMachine = StateMachine.new("Wandering",States)

    Obj.Connections = {}

    Obj.Connections[1] = Obj.GameStateMachine.StateChanged:Connect(function(OldState,NewState)
        local SwitchFunction = StateSwitchFunctions[OldState .. "___" .. NewState]
        if not SwitchFunction then
            error("CRITICAL ERROR: UNHANDLED STATE TRANSITION EXCEPTION: [" .. OldState:upper() .. "] TO [" .. NewState:upper() .. "]")
        else
            SwitchFunction(Obj)
        end
    end)

    return Obj
end

--// MEMBER FUNCTIONS

--// RETURN
return Handler