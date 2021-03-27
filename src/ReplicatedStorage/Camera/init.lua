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
    local newCFrame = Head:WaitForChild("Neck").C0

    Obj.Camera.CameraType = Enum.CameraType.Scriptable
    UserInputServ.MouseBehavior = Enum.MouseBehavior.LockCenter

    if Obj.Character then
        local C = Obj.Character
        local Head = C:WaitForChild("Head")
        Head.Transparency = 1
        -- Set up childadded event to catch any accessories not caught by the initial run through.
        Obj.Connections[1] = C.ChildAdded:Connect(function(child)
            if child:IsA("Accessory") then
                local H = child:WaitForChild("Handle", 3)
                H.Transparency = 1
            end
        end)
        -- Run through the character and set all accessory's transparency to 1.
        for _, acc in pairs(C:GetChildren()) do
            if acc:IsA("Accessory") then
                print(acc)
                local H = acc:FindFirstChild("Handle")
                H.Transparency = 1
            end
        end
    end

    Obj.Connections[2] = RunServ.RenderStepped:Connect(function()
        if Obj.Character then
            Obj:SetCFrame(Head, newCFrame)
        end
    end)

    Obj.Connections[3] = UserInputServ.InputChanged:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            local MouseDeltaX = input.Delta.X
            local MouseDeltaY = input.Delta.Y
            print("input: "..MouseDeltaX, MouseDeltaY)
        end
    end)

    Obj.Character:FindFirstChild("Humanoid").Died:Disconnect(Obj.Connections[2])

    return Obj
end

--// MEMBER FUNCTIONS
function Handler:SetCFrame(Head, CFrame : CFrame)
   Head.CFrame = CFrame
end

--// RETURN
return Handler