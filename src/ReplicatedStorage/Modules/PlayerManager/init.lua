--// SERVICES
local RepStore = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunServ = game:GetService("RunService")

--// REQUIRES
local StateMachine = require(RepStore.Network.Utility.States)
local Network = require(RepStore.Network.Utility.NetworkClient)
local StateSwitchFunctions = require(script.StateChangedFunctions)

--// CONSTANTS
local NULL = {}

--// VARIABLES
local Camera = workspace.CurrentCamera
local AnimationNames = {
    "WalkLeft",
    "WalkRight",
    "WalkForward",
    "WalkBackward",
    "Vault_Slow",
    "Vault_Fast",
    "Died",
    ""
}
local PlayerStates = {
    Idle = {
        Walk = "Walking",
        Run = "Running",
        Vault = "Slow_Vaulting",
        Attacked = "Damaged",
        PerformAction = "PerformingAction",
        Pause = "Pause",
    },
    Walking = {
        Stop = "Idle",
        Run = "Running",
        Vault = "slow_Vaulting",
        Attacked = "Damaged",
        PerformAction = "PerformingAction",
        Pause = "Pause"
    },
    Running = {
        Stop = "Idle",
        Walk = "Walking",
        Vault = "Fast_Vaulting",
        Attacked = "Damaged",
        PerformAction = "PerformingAction",
        Pause = "Pause"
    },
    Slow_Vaulting = {
        EndVault = "Idle"
    },
    Fast_Vaulting = {
        EndVault = "Running"
    },
    Damaged = {
        Died = "Dead",
        Recover = "Idle"
    },
    PerformingAction = {
        EndAction = "Idle",
        Attacked = "Damaged"
    },
    Pause = {
        Unpause = "Idle",
        Atacked = "Pause_Damaged"
    },
    Pause_Damaged = {
        Died = "Dead",
        Recover = "Pause"
    },
    Dead = {
        Ghost = "Ghosting"
    },
    Ghosting = {
        Respawn = "Idle"
    }
}

--// CONSTRUCTOR
local Handler = {}
Handler.__index = Handler

local function DefaultValues()
    return {
        StartingHealth = 100,
        Animations = {},
        InitialState = NULL,
        Player = NULL,
        Character = NULL
    }
end

function Handler.new(Data)
    Data = Data or {}
    local Obj = {}
    
    setmetatable(Obj,Handler)

    for i,v in pairs(DefaultValues()) do
        Obj[i] = Data[i] == nil and v or Data[i]
        if Obj[i] == NULL then error("Missing data for PlayerManager constructor:",i) end
    end

    --// INITIALIZATION
    Obj.GameStateMachine = StateMachine.new("Idle",PlayerStates)

    Obj.Connections = {}
    Obj.AnimationTracks = {}

    Obj.QueuedDamage = 0

    Obj.WalkAnimPlaying = false
    Obj.ActionAnimPlaying = false

    Obj.Connections[1] = Obj.GameStateMachine.StateChanged:Connect(function(OldState,NewState)
        local SwitchFunction = StateSwitchFunctions[OldState .. "___" .. NewState]
        if not SwitchFunction then
            error("CRITICAL ERROR: UNHANDLED STATE TRANSITION EXCEPTION: [" .. OldState:upper() .. "] TO [" .. NewState:upper() .. "] IN PLAYER MANAGER")
        else
            SwitchFunction(Obj)
        end
    end)

    if Obj.InitialState == "Dead" then
        Obj.QueuedDamage += 100
        Obj.GameStateMachine:switch("Attacked")
    end

    Obj.Character:WaitForChild("Humanoid"):WaitForChild("Animator")

    for _,AnimName in pairs(AnimationNames) do
        local Anim,AnimInd
        for i,v in pairs(Obj.Animations) do
            if v.Name == AnimName then
                Anim = v
                AnimInd = i
                break
            end
        end
        if not Anim then warn("Missing required Animation: \"" .. AnimName .. "\".") continue end
        Obj.AnimationTracks[AnimName] = Obj.Character.Humanoid.Animator:LoadAnimation(Anim)
        table.remove(Obj.Animations,AnimInd)
    end

    for i,v in pairs(Obj.Animations) do
        Obj.AnimationTracks[i] = Obj.AnimationTracks[i] or Obj.Character.Humanoid.Animator:LoadAnimation(v)
    end
    
    --// debugging purposes only:
    coroutine.wrap(function()
        while wait(0.1) do
            Obj:CalculateWalkWeights()
        end
    end)()

    return Obj
end

--// MEMBER FUNCTIONS
function Handler:Pause()

end

function Handler:TriggerAttacked()

end

function Handler:StartWalking()
    --self.Connections.WalkConnection
end

function Handler:IsWalkAnimating()
    return self.WalkAnimPlaying
end

function Handler:IsActionAnimating()
    return self.ActionAnimPlaying
end

function Handler:BeginWalkAnimation()

end

function Handler:CalculateWalkWeights()
    local Forward,Backward,Left,Right = UIS:IsKeyDown(Enum.KeyCode.W),UIS:IsKeyDown(Enum.KeyCode.S),UIS:IsKeyDown(Enum.KeyCode.A),UIS:IsKeyDown(Enum.KeyCode.D)
    if not (((Forward or Backward) and not (Forward and Backward)) or ((Right or Left) and not (Right and Left))) then return false end
    local MoveVector = Vector3.new(
        (Left and 1 or 0) + (Right and -1 or 0),
        0,
        (Forward and 1 or 0) + (Backward and -1 or 0)
    ).Unit
    MoveVector = Camera.CFrame:PointToWorldSpace(MoveVector) - Camera.CFrame.Position
    MoveVector = Vector3.new(MoveVector.X,0,MoveVector.Z).Unit
    local CharacterMoveVector : Vector3 = self.Character.HumanoidRootPart.CFrame.ZVector
    local Angle = math.acos(math.clamp(MoveVector:Dot(CharacterMoveVector),-1,1)) * 180/math.pi
    if Angle ~= 0 and Angle ~= 180 then
        Angle *= MoveVector:Cross(CharacterMoveVector).Unit.Y
    end
    local Tolerance = _G.Services.Character.CameraHandler:CalculateTolerance()
    print(math.clamp(1 - math.abs(Angle - 90)/90,0,1))
    return
    math.clamp(1 - (math.abs(Angle)/90),0,1), --// Forward
    math.clamp(math.abs(Angle)/90 - 1,0,1), --// Backward
    math.clamp(1 - math.abs(Angle + 90)/90,0,1), --// Left
    math.clamp(1 - math.abs(Angle - 90)/90,0,1) --// Right
end

--// RETURN
return Handler