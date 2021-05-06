--// SERVICES
local RepStore = game:GetService("ReplicatedStorage")
local RunServ = game:GetService("RunService")

--// REQUIRES
local StateMachine = require(RepStore.Network.Utility.States)
local StateSwitchFunctions = require(script.StateChangedFunctions)

--// CONSTANTS
local NULL = {}

--// VARIABLES
local States = {
    Pre_Game = {
        StartGame = "Match_Day"
    },
    Match_Day = {
        Transition = "Match_Day_To_Night",
        EndGame = "Post_Game"
    },
    Match_Day_To_Night = {
        Transition = "Match_Night",
        EndGame = "Post_Game"
    },
    Match_Night = {
        Transition = "Match_Night_To_Day",
        EndGame = "Post_Game"
    },
    Match_Night_To_Day = {
        Transition = "Match_Day",
        EndGame = "Post_Game"
    },
    Post_Game = {
        StartPreGame = "Pre_Game"
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
    Obj.GameStateMachine = StateMachine.new("Pre_Game",States)
    Obj.GameTime = 12

    Obj.Connections = {}

    Obj.Connections[1] = Obj.GameStateMachine.StateChanged:Connect(function(OldState,NewState)
        local SwitchFunction = StateSwitchFunctions[OldState .. "___" .. NewState]
        if not SwitchFunction then
            error("CRITICAL ERROR: UNHANDLED STATE TRANSITION EXCEPTION: [" .. OldState:upper() .. "] TO [" .. NewState:upper() .. "]")
        else
            SwitchFunction(Obj)
        end
    end)

    Obj.Connections[2] = RunServ.Heartbeat:Connect(function()
        
    end)

    return Obj
end

--// MEMBER FUNCTIONS

--// RETURN
return Handler