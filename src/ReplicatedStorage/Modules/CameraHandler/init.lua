--// SERVICES
local RunServ = game:GetService("RunService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Services = _G.Services

--// REQUIRES

--// CONSTANTS
local NULL = {}
local ROTATION_SPEED = 5
local MAX_REVERSE_ROTATION = 0
local MAX_STRAFE_ROTATION = 25
local MAX_IDLE_ROTATION = 80
local SHOULDER_DEADZONE = 0.2
local FEET_DEADZONE = 0.2

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
        Enabled = true
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
    Obj.Pitch, Obj.Yaw = 0, 0

    Obj.Camera.CameraType = Enum.CameraType.Scriptable
    Obj.Neck = Obj.Character:WaitForChild("Head"):FindFirstChild("Neck")
    Obj.CameraBlur = Instance.new("BlurEffect")
    Obj.CameraBlur.Parent = Lighting
    Obj.CameraBlur.Enabled = true
    Obj.CameraBlur.Size = 0

    if Obj.Character then
        local Character = Obj.Character
        Head.Transparency = 1
        -- Set up childadded event to catch any accessories not caught by the initial run through.
        Obj.Connections[1] = Character.ChildAdded:Connect(function(child)
            if child:IsA("Accessory") then
                local Handle = child:WaitForChild("Handle")
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
    Obj:SetMouseBehavior(Enum.MouseBehavior.LockCenter)
    Obj.Connections[2] = RunServ:BindToRenderStep("CameraUpdate",250,function()
        if not Obj.Enabled then Obj.CameraBlur.Size = 0 return end
        Obj.CameraBlur.Size = math.log(math.max(UIS:GetMouseDelta().Magnitude-7,0))*2
        if Obj.Character then
            CameraRot = CFrame.Angles(0, math.rad(Obj.Yaw), 0) * CFrame.Angles(math.rad(Obj.Pitch), 0, 0)
            CameraRot = CFrame.fromMatrix(
                HRP.CFrame:PointToWorldSpace(Vector3.new(0, 1.25, -.25)) + Vector3.new(CameraRot.YVector.X,0, CameraRot.YVector.Z) * .5,
                CameraRot.XVector,
                CameraRot.YVector,
                CameraRot.ZVector
            )
            Obj.Camera.CFrame = CameraRot
            --Obj:SetCFrame(Obj.Camera.CFrame:Lerp(CameraRot, 0.8))
            CameraRot = Obj.Camera.CFrame
            local HRPZ = -Vector3.new(CameraRot.ZVector.X,0, CameraRot.ZVector.Z).Unit
            local Tolorance = Obj:CalculateTolerance()
            if not UIS:IsKeyDown(Enum.KeyCode.W) and UIS:IsKeyDown(Enum.KeyCode.S) then
                Tolorance = math.clamp(Tolorance, 0, MAX_REVERSE_ROTATION)
            elseif UIS:IsKeyDown(Enum.KeyCode.A) or UIS:IsKeyDown(Enum.KeyCode.D) then
                Tolorance = math.clamp(Tolorance, 0, MAX_STRAFE_ROTATION)
            end
            local targetHRPCFrame = CFrame.lookAt(HRP.Position, HRP.Position + HRPZ)
            local AngleDiff = targetHRPCFrame:ToObjectSpace(HRP.CFrame)
            local DotResult = AngleDiff.ZVector.Unit:Dot(Vector3.new(0, 0, 1))
            local Angle = math.acos(DotResult) * 180/math.pi * math.sign(AngleDiff.ZVector.X)
            Angle = math.clamp(Angle, -Tolorance, Tolorance)
            AngleDiff = CFrame.Angles(0, math.rad(Angle), 0)
            --print(Angle, Tolorance)
            HRP.CFrame = targetHRPCFrame * AngleDiff
            --HRP.CFrame = HRP.CFrame:Lerp(targetHRPCFrame * AngleDiff, .7) --// produced some weird results, removing this for now
            for _, bp in pairs(Obj.Character:GetChildren()) do
                if bp:IsA("MeshPart") then
                    bp.LocalTransparencyModifier = 0
                end
            end
        end
    end)

    Obj.Connections[4] = Obj.Character:FindFirstChild("Humanoid").Died:Connect(function()
        for _, connection in pairs(Obj.Connections) do
            connection:Disconnect()
        end
    end)

    Obj:Enable()

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

function Handler:CalculateTolerance()
    local YFactor = (math.abs(self.Camera.CFrame.ZVector.Y)-SHOULDER_DEADZONE) * 1/(1-SHOULDER_DEADZONE-FEET_DEADZONE)
    YFactor = math.clamp(YFactor,0,1)
    return (1 - YFactor) * MAX_IDLE_ROTATION
end

function Handler:IsEnabled()
    return self.Enabled
end

function Handler:Enable()
    if not self.Connections[3] then
        self.Connections[3] = UIS.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                local DeltaX, DeltaY = -input.Delta.X, -input.Delta.Y
                self.Pitch = math.clamp(self.Pitch + DeltaY/ROTATION_SPEED, -85, 85)
                self.Yaw += DeltaX/ROTATION_SPEED
            end
        end)
    end

    self.Enabled = true
end

function Handler:Disable()
    if self.Connections[3] then
        self.Connections[3]:Disconnect()
        self.Connections[3] = nil
    end

    self.Enabled = false
end

function Handler:SetPitch(Pitch)
    self.Pitch = math.clamp(Pitch,-85,85)
end

function Handler:SetYaw(Yaw)
    self.Yaw = Yaw
end

function Handler:SetMouseBehavior(MouseBehavior : Enum)
    UIS.MouseBehavior = MouseBehavior
end

--// RETURN
return Handler