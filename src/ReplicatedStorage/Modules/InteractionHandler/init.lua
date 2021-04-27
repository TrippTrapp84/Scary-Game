--// SERVICES
local ColServ = game:GetService("CollectionService")
local RunServ = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local RepStore = game:GetService("ReplicatedStorage")
local Services = _G.Services

--// REQUIRES
local InteractHandlers = {}
for i,v in pairs(RepStore:WaitForChild("Modules"):WaitForChild("InteractionModules"):GetChildren()) do
    InteractHandlers[v.Name] = require(v)
end

--// CONSTANTS
local NULL = {}

local MIN_INTERACT_DISTANCE = 5

--// VARIABLES
local Camera = workspace.CurrentCamera
local Assets = RepStore:WaitForChild("Assets")
local Interactions = Assets:WaitForChild("InteractionSets")
local ActiveInteractions = workspace.Map.ScriptedObjects.Interactables

--// CONSTRUCTOR
local Handler = {}
Handler.__index = Handler

local function DefaultValues()
    return {
        Character = NULL
    }
end

function Handler.new(Data)
    Data = Data or {}
    local Obj = {}

    setmetatable(Obj,Handler)

    for i,v in pairs(DefaultValues()) do
        Obj[i] = Data[i] == nil and v or Data[i]
        if Obj[i] == NULL then error("Missing data for InteractionHandler constructor:",i) end
    end

    --// INITIALIZATION
    Obj.Connections = {}
    Obj.HRP = Obj.Character:WaitForChild("HumanoidRootPart")
    Obj.CurrentInteract = nil

    Obj.Connections[1] = RunServ.Heartbeat:Connect(function()
        local InteractionSets = ActiveInteractions:GetChildren()
        local InteractParts = {}
        for i,v in ipairs(InteractionSets) do
            InteractParts[i] = v.InteractPart
        end
        local RayParams = RaycastParams.new()
        RayParams.FilterType = Enum.RaycastFilterType.Whitelist
        RayParams.FilterDescendantsInstances = InteractParts
        local RayRes = workspace:Raycast(Camera.CFrame.Position,Camera.CFrame.ZVector * MIN_INTERACT_DISTANCE,RayParams)
        if RayRes then
            Obj:SetCurrentInteract(InteractionSets[table.find(InteractParts,RayRes.Instance)])
        else
            Obj:SetCurrentInteract(nil)
        end
    end)

    Obj.Connections[2] = UIS.InputBegan:Connect(function(input,gp)
        if gp or not Obj.CurrentInteract  or Obj.InAction then return end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.E then
            Obj:Interact()
        end
    end)

    return Obj
end

--// MEMBER FUNCTIONS
function Handler:SetCurrentInteract(Interact)
    self.CurrentInteract = Interact
end

function Handler:Interact()
    local InteractHandler = InteractHandlers[self.CurrentInteract.HandlerName.Value]
    Services.Character.PlayerManager:TriggerInteraction()
    self.InAction = true
    InteractHandlers(self.CurrentInteract)
    self.InAction = false
end

--// RETURN
return Handler