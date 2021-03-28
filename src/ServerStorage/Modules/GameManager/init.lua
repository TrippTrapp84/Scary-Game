--// SERVICES
local RepStore = game:GetService("ReplicatedStorage")

--// REQUIRES
local StateMachine = require(RepStore.Network.Utility.States)

--// CONSTANTS
local NULL = {}

--// VARIABLES

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
        if Obj[i] == NULL then error("Missing data for CLASS_NAME_HERE constructor:",i) end
    end

    --// INITIALIZATION

    return Obj
end

--// MEMBER FUNCTIONS

--// RETURN
return Handler