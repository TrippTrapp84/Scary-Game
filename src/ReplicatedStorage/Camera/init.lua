--// SERVICES
local RunServ = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputServ = game:GetService("UserInputService")
local Services = _G.Services

--// REQUIRES

--// CONSTANTS
local NULL = {}
local RotSpeed = 1
local MaxReverseLinearAngle = 0
local MaxStrafeLinearAngle = 25
local MaxLinearAngle = 80

--// VARIABLES
local Mouse = Players.LocalPlayer:GetMouse()

--// LOCAL FUNCTIONS
local function ErrorFunction(x)
    -- constants
    local a1 =  0.254829592
    local a2 = -0.284496736
    local a3 =  1.421413741
    local a4 = -1.453152027
    local a5 =  1.061405429
    local p  =  0.3275911

    -- Save the sign of x
    local sign = 1
    if x < 0 then
        sign = -1
    end
    x = math.abs(x)

    -- A&S formula 7.1.26
    local t = 1.0/(1.0 + p*x)
    local y = 1.0 - (((((a5*t + a4)*t) + a3)*t + a2)*t + a1)*t*math.exp(-x*x)

    return sign*y
end

local function SmoothLerp(x)
    local z = math.sqrt(32) * (x - 0.5)
    return 0.5 * ErrorFunction(z) * 1/0.99993662792787
end

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
    Obj.Neck = Obj.Character:WaitForChild("Head"):FindFirstChild("Neck")

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
        UserInputServ.MouseBehavior = Enum.MouseBehavior.LockCenter
        if Obj.Character then
            CameraRot = CFrame.Angles(0, math.rad(Yaw), 0) * CFrame.Angles(math.rad(Pitch), 0, 0)
            CameraRot = CFrame.fromMatrix(
                HRP.CFrame:PointToWorldSpace(Vector3.new(0, 1.25, -.25)) + Vector3.new(CameraRot.YVector.X,0, CameraRot.YVector.Z) * .5,
                CameraRot.XVector,
                CameraRot.YVector,
                CameraRot.ZVector
            )
            Obj:SetCFrame(Obj.Camera.CFrame:Lerp(CameraRot, 0.8))
            CameraRot = Obj.Camera.CFrame
            local HRPZ = -Vector3.new(CameraRot.ZVector.X,0, CameraRot.ZVector.Z).Unit
            local Tolorance = (1 - math.abs(CameraRot.ZVector.Y)) * MaxLinearAngle
            if not UserInputServ:IsKeyDown(Enum.KeyCode.W) and UserInputServ:IsKeyDown(Enum.KeyCode.S) then
                Tolorance = math.clamp(Tolorance, 0, MaxReverseLinearAngle)
            elseif UserInputServ:IsKeyDown(Enum.KeyCode.A) or UserInputServ:IsKeyDown(Enum.KeyCode.D) then
                Tolorance = math.clamp(Tolorance, 0, MaxStrafeLinearAngle)
            end
            local targetHRPCFrame = CFrame.lookAt(HRP.Position, HRP.Position + HRPZ)
            local AngleDiff = targetHRPCFrame:ToObjectSpace(HRP.CFrame)
            local DotResult = AngleDiff.ZVector.Unit:Dot(Vector3.new(0, 0, 1))
            local Angle = math.acos(DotResult) * 180/math.pi * math.sign(AngleDiff.ZVector.X)
            Angle = math.clamp(Angle, -Tolorance, Tolorance)
            AngleDiff = CFrame.Angles(0, math.rad(Angle), 0)
            --print(Angle, Tolorance)
            HRP.CFrame = HRP.CFrame:Lerp(targetHRPCFrame * AngleDiff, .7)
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
            Pitch = math.clamp(Pitch + DeltaY/RotSpeed, -85, 85)
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
function Handler:SetCFrame(CF : CFrame)
    self.Camera.CFrame = CF
    -- self.Neck.C0 = CFrame.fromMatrix(
    --     self.Neck.C0.Position,
    --     CF.XVector,
    --     CF.YVector,
    --     CF.ZVector
    -- )
end

--// RETURN
return Handler