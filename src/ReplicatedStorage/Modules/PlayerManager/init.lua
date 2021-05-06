--// SERVICES
local RepStore = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunServ = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Services = _G.Services

--// REQUIRES
local StateMachine = require(RepStore.Network.Utility.States)
local Network = require(RepStore.Network.Utility.NetworkClient)
local StateSwitchFunctions = require(script.StateChangedFunctions)
local PlayerModule = require(game.Players.LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"))

--// CONSTANTS
local NULL = {}
local MIN_VAULT_TRIGGER_DIST = 4
local MIN_VAULT_DOT_DIRECTION = math.cos(1/2)

--// VARIABLES
local Assets = RepStore:WaitForChild("Assets")
local VaultTriggers = workspace.Map.ScriptedObjects.VaultingTriggers:GetChildren()
local Animations = Assets.Animations
local Camera = workspace.CurrentCamera
local Controls = PlayerModule:GetControls()
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
        Vault = "Slow_Vaulting",
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
        Recover = "Idle"
    },
    Dead = {
        Ghost = "Ghosting"
    },
    Ghosting = {
        Respawn = "Idle"
    }
}

--// LOCAL FUNCTIONS
function IsLeftShiftDown()
    return UIS:IsKeyDown(Enum.KeyCode.LeftShift)
end
function IsLeftShiftNotDown()
    return not IsLeftShiftDown()
end

function BoxSignedDistance(Point, BoxCenter, BoxSize)
   Point -= BoxCenter
   local Value = Vector3.new(
       math.max(math.abs(Point.X) - BoxSize.X,0),
       math.max(math.abs(Point.Y) - BoxSize.Y,0),
       math.max(math.abs(Point.Z) - BoxSize.Z,0)
   )

  return Value.Magnitude;
end

--// CONSTRUCTOR
local Handler = {}
Handler.__index = Handler

local function DefaultValues()
    return {
        StartingHealth = 100,
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
    Obj.PlayerStateMachine = StateMachine.new("Idle",PlayerStates)
    Obj.OnStateChanged = Obj.PlayerStateMachine.StateChanged

    Obj.Connections = {}
    Obj.Animations = {}
    Obj.AnimationTracks = {}

    Obj.QueuedDamage = 0

    Obj.ControlsEnabled = false
    Obj.CameraEnabled = false

    Obj.Connections[1] = Obj.OnStateChanged:Connect(function(OldState,NewState)
        local SwitchFunction = StateSwitchFunctions[OldState .. "___" .. NewState]
        if not SwitchFunction then
            error("CRITICAL ERROR: UNHANDLED STATE TRANSITION EXCEPTION: [[ " .. OldState:upper() .. " ]] TO [[ " .. NewState:upper() .. " ]] IN PLAYER MANAGER")
        else
            SwitchFunction(Obj)
        end
    end)

    Obj.Connections[2] = UIS.InputBegan:Connect(function(input,gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == Enum.KeyCode.LeftControl then
                Obj:SetState("Vault")
            elseif input.KeyCode == Enum.KeyCode.Backquote and not GuiService.MenuIsOpen then
                local _ = Obj:SetState("Pause") or Obj:SetState("Unpause")
            end
        end        
    end)

    Obj.Character:WaitForChild("Humanoid"):WaitForChild("Animator")

    local TempAnimsTable = Animations:GetDescendants()
    for i,v in pairs(TempAnimsTable) do
        if v:IsA("Animation") then
            Obj.Animations[v.Name] = v
        end
    end

    for i,v in pairs(Obj.Animations) do
        Obj.AnimationTracks[i] = Obj.AnimationTracks[i] or Obj.Character.Humanoid.Animator:LoadAnimation(v)
    end

    Obj:ToggleIdleState()

    return Obj
end

--// MEMBER FUNCTIONS
function Handler:TogglePaused(Paused)
    if Paused then self:BeginAction() else self:EndAction() end
    Services.Client.PauseMenuHandler:TogglePaused(Paused)
end

function Handler:TriggerAttacked()

end

function Handler:SetControlsEnabled(Enabled)
    if Enabled == self.ControlsEnabled then return end
    self.ControlsEnabled = Enabled
    if Enabled then
        Controls:Enable()
    else
        Controls:Disable()
    end
end

function Handler:SetCameraEnabled(Enabled)
    if Enabled == self.CameraEnabled then return end
    self.CameraEnabled = Enabled
    if Enabled then
        Services.Character.CameraHandler:Enable()
    else
        Services.Character.CameraHandler:Disable()
    end
end

function Handler:SetState(Action)
    if not PlayerStates[self:GetState()][Action] then return false end
    self.PlayerStateMachine:switch(Action)
    return true
end

function Handler:GetState()
    return self.PlayerStateMachine.current_state
end

function Handler:BeginAction()
    self:SetControlsEnabled(false)
    self:SetCameraEnabled(false)
end

function Handler:EndAction()
    self:SetControlsEnabled(true)
    self:SetCameraEnabled(true)
end

do --// MOVEMENT FUNCTIONS
    function Handler:GetWalkAnimTracks()
        return self.AnimationTracks["WalkForward"],self.AnimationTracks["WalkBackward"],self.AnimationTracks["WalkLeft"],self.AnimationTracks["WalkRight"]
    end

    function Handler:GetRunAnimTracks()
        return self.AnimationTracks["RunForward"],self.AnimationTracks["RunBackward"],self.AnimationTracks["RunLeft"],self.AnimationTracks["RunRight"]
    end

    function Handler:IsMoving()
        local Forward,Backward,Left,Right = UIS:IsKeyDown(Enum.KeyCode.W),UIS:IsKeyDown(Enum.KeyCode.S),UIS:IsKeyDown(Enum.KeyCode.A),UIS:IsKeyDown(Enum.KeyCode.D)
        if not (((Forward or Backward) and not (Forward and Backward)) or ((Right or Left) and not (Right and Left))) then return false end
        return true
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

        return true,
        math.clamp(1 - (math.abs(Angle)/90),0,1), --// Forward
        math.clamp(math.abs(Angle)/90 - 1,0,1), --// Backward
        math.clamp(1 - math.abs(Angle + 90)/90,0,1), --// Left
        math.clamp(1 - math.abs(Angle - 90)/90,0,1) --// Right
    end

    function Handler:PlayMovementAnimations(ForwardAnim,BackwardAnim,LeftAnim,RightAnim)
        local IsMoving,FWeight,BWeight,LWeight,RWeight = self:CalculateWalkWeights()
        
        if not ForwardAnim.IsPlaying then ForwardAnim:Play() end
        if not BackwardAnim.IsPlaying then BackwardAnim:Play() end
        if not LeftAnim.IsPlaying then LeftAnim:Play() end
        if not RightAnim.IsPlaying then RightAnim:Play() end

        ForwardAnim:AdjustWeight(FWeight)
        BackwardAnim:AdjustWeight(BWeight)
        LeftAnim:AdjustWeight(LWeight)
        RightAnim:AdjustWeight(RWeight)
        print("Beginning walk animations")
    end

    function Handler:BeginWalkAnimation()
        self:PlayMovementAnimations(self:GetWalkAnimTracks())
    end

    function Handler:BeginRunAnimation()
        self:PlayMovementAnimations(self:GetRunAnimTracks())
    end

    function Handler:ValidateVault()
        local ZVector = Vector3.new(Camera.CFrame.ZVector.X,0,Camera.CFrame.ZVector.Z).Unit
        local Trigger,TriggerDist,TriggerDot = nil,0,0
        for i,v in pairs(VaultTriggers) do
            local Dist = BoxSignedDistance(Camera.CFrame.Position,v.Position,v.Size)
            local Dot = math.abs(ZVector:Dot(v.CFrame.ZVector))
            local Offset = (self.Character.HumanoidRootPart.Position - v.Position).Unit
            if Offset.Magnitude < (Offset - self.Character.HumanoidRootPart.CFrame.ZVector*TriggerDist).Magnitude then continue end
            if Dist > MIN_VAULT_TRIGGER_DIST then continue end
            if Dot < MIN_VAULT_DOT_DIRECTION then continue end
            if Dot > TriggerDot then
                TriggerDot = Dot
                Trigger = v
                TriggerDist = Dist
            end
        end
        return Trigger,TriggerDist
    end

    function Handler:ToggleVault(IsRun)
        local VaultPart,VaultTriggerDist = self:ValidateVault()
        if not VaultPart then self.PlayerStateMachine:switch("EndVault") return end
        self:BeginAction()
        local VaultAnim : AnimationTrack
        if IsRun then
            VaultAnim = self.AnimationTracks.FastVault
        else
            VaultAnim = self.AnimationTracks.SlowVault
        end

        local HRPCF : CFrame = self.Character.HumanoidRootPart.CFrame
        local ZVector : Vector3 = VaultPart.CFrame.ZVector
        if (HRPCF.Position - VaultPart.Position).Unit:Dot(ZVector) < 0 then
            ZVector = -ZVector
        end
        Services.Character.CameraHandler:SetPitch(0)
        local YawAngle = math.acos(Vector3.new(0,0,1):Dot(ZVector))*180/math.pi
        Services.Character.CameraHandler:SetYaw(YawAngle)

        self.Character.HumanoidRootPart.CFrame = CFrame.fromMatrix(
            HRPCF.Position,
            HRPCF.YVector:Cross(ZVector),
            Vector3.new(0,1,0),
            ZVector
        )
        HRPCF = self.Character.HumanoidRootPart.CFrame

        local VaultDistance = VaultTriggerDist + VaultPart.Size.Z + 2

        VaultAnim:Play()
        repeat
            self.Character.HumanoidRootPart.CFrame = CFrame.fromMatrix(
                HRPCF:PointToWorldSpace(Vector3.new(0,0,-(VaultAnim.TimePosition / VaultAnim.Length) * VaultDistance)),
                HRPCF.XVector,
                HRPCF.YVector,
                HRPCF.ZVector
            )
            RunServ.Heartbeat:Wait()
        until not VaultAnim.IsPlaying
        self:EndAction()
        self.PlayerStateMachine:switch("EndVault")
    end

    function Handler:ToggleMovement(IsRun)

        local Switched = false
        local EndCon = self.OnStateChanged:Connect(function()
            Switched = true
        end)
        local FAnim,BAnim,LAnim,RAnim : AnimationTrack
        local CheckFunction,CheckFunctionState
        if IsRun then
            FAnim,BAnim,LAnim,RAnim = self:GetRunAnimTracks()
            CheckFunction = IsLeftShiftNotDown
            CheckFunctionState = "Walk"
            self:BeginRunAnimation()
        else
            FAnim,BAnim,LAnim,RAnim = self:GetWalkAnimTracks()
            CheckFunction = IsLeftShiftDown
            CheckFunctionState = "Run"
            self:BeginWalkAnimation()
        end
        repeat
            RunServ.RenderStepped:Wait()
            local IsMoving,WeightForward,WeightBackward,WeightLeft,WeightRight = self:CalculateWalkWeights()
            if not IsMoving then
                self.PlayerStateMachine:switch("Stop")
                Switched = true
            elseif CheckFunction() then
                self.PlayerStateMachine:switch(CheckFunctionState)
            else
                FAnim:AdjustWeight(WeightForward)
                BAnim:AdjustWeight(WeightBackward)
                LAnim:AdjustWeight(WeightLeft)
                RAnim:AdjustWeight(WeightRight)
            end
        until Switched
        EndCon:Disconnect()
    end
    
    function Handler:ToggleIdleState()
        local ForwardAnim,BackwardAnim,LeftAnim,RightAnim : AnimationTrack = self:GetWalkAnimTracks()
        if ForwardAnim.IsPlaying then ForwardAnim:Stop() end
        if BackwardAnim.IsPlaying then BackwardAnim:Stop() end
        if LeftAnim.IsPlaying then LeftAnim:Stop() end
        if RightAnim.IsPlaying then RightAnim:Stop() end
        
        local Switched = false
        local EndCon = self.OnStateChanged:Connect(function()
            Switched = true
        end)
        repeat
            RunServ.RenderStepped:Wait()
            if self:IsMoving() then
                if UIS:IsKeyDown("LeftShift") then
                    self.PlayerStateMachine:switch("Run")
                else
                    self.PlayerStateMachine:switch("Walk")
                end
                Switched = true
            end
        until Switched
        EndCon:Disconnect()
    end
end


--// RETURN
return Handler