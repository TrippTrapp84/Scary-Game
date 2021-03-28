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
local RotSpeed = 1


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
    local CameraRot = nil
    local Pitch, Yaw = 0, 0

    Obj.Camera.CameraType = Enum.CameraType.Scriptable
    UserInputServ.MouseBehavior = Enum.MouseBehavior.LockCenter

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
            CameraRot = CFrame.Angles(0, math.rad(Yaw), 0) * CFrame.Angles(math.rad(Pitch), 0, 0)
            CameraRot = CFrame.fromMatrix(
                HRP.CFrame:PointToWorldSpace(Vector3.new(0, 1, 0)) + CameraRot.YVector,
                CameraRot.XVector,
                CameraRot.YVector,
                CameraRot.ZVector
            )
            Obj:SetCFrame(CameraRot)
            for _, bp in pairs(Obj.Character:GetChildren()) do
                if bp:IsA("MeshPart") then
                    bp.LocalTransparencyModifier = 0
                end
            end
        end
    end)

    Obj.Connections[3] = UserInputServ.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            local DeltaX, DeltaY = -input.Delta.X, -input.Delta.Y
            Pitch = math.clamp(Pitch + DeltaY/RotSpeed, -90, 90)
            Yaw += DeltaX/RotSpeed
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
function Handler:SetCFrame(CFrame : CFrame)
    self.Camera.CFrame = CFrame
end

--// RETURN
return Handler