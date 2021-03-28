--// SERVICES
local RunServ = game:GetService("RunService")
local Players = game:GetService("Players")
local Services = _G.Services

--// REQUIRES

--// CONSTANTS
local NULL = {}

--// VARIABLES
local Mouse = Players.LocalPlayer:GetMouse()
local UserInputServ = game:GetService("UserInputService")
local HeadScale = 1.2

--// CONSTRUCTOR
local Handler = {}
Handler.__index = Handler

local function DefaultValues()
    return {
        Player = NULL,
        Character = NULL,
        Camera = NULL,
    }
end

function Handler.new(Data)
    Data = Data or {}
    local Obj = {}
    
    setmetatable(Obj,Handler)

    for i,v in pairs(DefaultValues()) do
        Obj[i] = Data[i] == nil and v or Data[i]
        if Obj[i] == NULL then error("Missing data for Camera constructor:",i) end
    end

    --// INITIALIZATION
    Obj.Connections = {}

    local Head = Obj.Character:WaitForChild("Head")
    local HRP = Obj.Character:WaitForChild("HumanoidRootPart")
    local newVector = nil
    local newOffset = CFrame.Angles(0,0,0)

    -- Obj.Camera.CameraType = Enum.CameraType.Scriptable
    -- UserInputServ.MouseBehavior = Enum.MouseBehavior.LockCenter

    if Obj.Character then
        local Character = Obj.Character
        local Head = Character:WaitForChild("Head")
        Head.Transparency = 1
        -- Set up childadded event to catch any accessories not caught by the initial run through.
        Obj.Connections[1] = Character.ChildAdded:Connect(function(child)
            if child:IsA("Accessory") then
                local Handle = child:WaitForChild("Handle", 3)
                Handle.Transparency = 1
            end
        end)
        -- Run through the character and set all accessory's transparency to 1.
        for _, acc in pairs(Character:GetChildren()) do
            if acc:IsA("Accessory") then
                local Handle = acc:FindFirstChild("Handle")
                Handle.Transparency = 1
            end
        end
    end

    Obj.Connections[2] = RunServ.RenderStepped:Connect(function()
        if Obj.Character then
            for _, bp in pairs(Obj.Character:GetChildren()) do
                if bp:IsA("MeshPart") then
                    bp.LocalTransparencyModifier = 0
                end
            end
        end
    end)

    Obj.Connections[3] = RunServ.Heartbeat:Connect(function(Delta)
        if Obj.Character then
            local CameraCFrame = HRP.CFrame:ToObjectSpace(Obj.Camera.CFrame)
            newVector = CameraCFrame.YVector * HeadScale
            -- newCFrame = HRP.CFrame 
            -- newCFrame = CFrame.fromMatrix(
            --     newCFrame.Position,
            --     Obj.Camera.CFrame.XVector,
            --     Obj.Camera.CFrame.YVector,
            --     Obj.Camera.CFrame.ZVector
            --  )
            --  newCFrame *= CFrame.new(0,1,0)
            Obj:SetOffset(Obj.Character:WaitForChild("Humanoid"), newVector)
        end
    end)

    Obj.Connections[4] = Obj.Character:FindFirstChild("Humanoid").Died:Connect(function()
        for _, connection in pairs(Obj.Connections) do
            connection:Disconnect()
        end
    end)

    return Obj
end

--// MEMBER FUNCTIONS
function Handler:SetOffset(Humanoid, Vector : Vector3)
    Humanoid.CameraOffset = Vector
end

--// RETURN
return Handler