--// SERVICES
local RepStore = game:GetService("ReplicatedStorage")
local RunServ = game:GetService("RunService")
local Players = game:GetService("Players")

--// REQUIRES

--// CONSTANTS
local NULL = {}
local IMAGE_SCALE = 3

--// VARIABLES
local Assets = RepStore:WaitForChild("Assets")
local ProjectionPlane : MeshPart = Assets["16BoneProjectionPlane"]

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
    Obj.Connections = {}
    Obj.TrackingAnimationConnections = {}

    Obj.Connections[1] = Players.PlayerAdded:Connect(function(plr)
        plr.CharacterAdded:Connect(function(char)
            Obj:TrackCharacterFootprints(plr,char)
        end)
    end)

    for i,plr in pairs(Players:GetPlayers()) do
        plr.CharacterAdded:Connect(function(char)
            Obj:TrackCharacterFootprints(plr,char)
        end)
        if plr.Character then
            Obj:TrackCharacterFootprints(plr,plr.Character)
        end
    end

    return Obj
end

--// MEMBER FUNCTIONS
function Handler:TrackCharacterFootprints(Player,Character)
    local Animator = Character:WaitForChild("Humanoid"):WaitForChild("Animator")
    Animator.AnimationPlayed:Connect(function(AnimTrack)
        if AnimTrack.Name ~= "WalkForward" then return end
        if self.TrackingAnimationConnections[Player.UserId] then
            for i,v in pairs(self.TrackingAnimationConnections[Player.UserId]) do
                v:Disconnect()
            end
            self.TrackingAnimationConnections[Player.UserId] = nil
        end
        self.TrackingAnimationConnections[Player.UserId] = {}
        self.TrackingAnimationConnections[Player.UserId][1] = AnimTrack:GetMarkerReachedSignal("StepLeft"):Connect(function()
            self:MakeFootprint(Character,Character.LeftFoot)
        end)
        self.TrackingAnimationConnections[Player.UserId][2] = AnimTrack:GetMarkerReachedSignal("StepRight"):Connect(function()
            self:MakeFootprint(Character,Character.RightFoot)
        end)
    end)
    Character.Humanoid.Died:Connect(function()
        if not self.TrackingAnimationConnections[Player.UserId] then return end
        for _,v in pairs(self.TrackingAnimationConnections[Player.UserId]) do
           v:Disconnect()
        end
    end)
end

function Handler:MakeFootprint(Character : Model,Foot : MeshPart)
    local RayParams = RaycastParams.new()
    local OffsetFootPos = Foot.Position + Vector3.new(0,1.5,0)
    RayParams.IgnoreWater = true
    RayParams.FilterDescendantsInstances = {Character,workspace.Footprints}
    local RayRes = workspace:Raycast(OffsetFootPos,Vector3.new(0,-2,0),RayParams)
    if not RayRes then return end
    local TexProj = ProjectionPlane:Clone()
    local FootCF = CFrame.lookAt(OffsetFootPos,OffsetFootPos + Vector3.new(Foot.CFrame.ZVector.X,0,Foot.CFrame.ZVector.Z))
    local BoneIndex = 1
    local NoRayInds = {}
    local MaxHeight,MinHeight = -math.huge,math.huge
    for x = -2,2 do
        if x == 0 then continue end
        for z = 2,-2,-1 do
            if z == 0 then continue end
            local FootRayPosition = FootCF:PointToWorldSpace(Vector3.new((x - math.sign(x) * 0.5)/IMAGE_SCALE,0,(z - math.sign(z) * 0.5)/IMAGE_SCALE))
            local FootRayRes = workspace:Raycast(FootRayPosition,Vector3.new(0,-5,0),RayParams)
            if not FootRayRes then
                NoRayInds[#NoRayInds + 1] = {BoneIndex,FootRayPosition}
            else
                local Position = FootRayRes.Position + Vector3.new(0,0.05,0)
                TexProj[BoneIndex].WorldPosition = Position
                MaxHeight = math.max(MaxHeight,Position.Y)
                MinHeight = math.min(MinHeight,Position.Y)
                if MaxHeight - MinHeight > 1 then return end
            end
            BoneIndex += 1
        end
    end
    while NoRayInds[1] do
        local CopyRayInds = {table.unpack(NoRayInds)}
        for i,v in pairs(NoRayInds) do
            local BoneInd = v[1]
            local BoneRayPos = v[2]
            local AdjacentBones = {
                not table.find(CopyRayInds,BoneInd + 4) and TexProj:FindFirstChild(BoneInd + 4) or nil,
                not table.find(CopyRayInds,BoneInd - 4) and TexProj:FindFirstChild(BoneInd - 4) or nil,
                not table.find(CopyRayInds,BoneInd + 1) and TexProj:FindFirstChild(BoneInd + 1) or nil,
                not table.find(CopyRayInds,BoneInd - 1) and TexProj:FindFirstChild(BoneInd - 1) or nil
            }
            if #AdjacentBones == 0 then continue end
            local AveragePos = Vector3.new()
            for _,Bone in pairs(AdjacentBones) do
                AveragePos += Bone.WorldPosition
            end
            AveragePos /= #AdjacentBones
            TexProj[BoneInd].WorldPosition = Vector3.new(BoneRayPos.X,AveragePos.Y,BoneRayPos.Z)
            table.remove(CopyRayInds,table.find(CopyRayInds,v))
        end
        NoRayInds = CopyRayInds
    end
    TexProj.Anchored = true
    TexProj.CanCollide = false
    --TexProj.CanTouch = false --// disabled until this feature gets fixed
    TexProj.Parent = workspace.Footprints
end

--// RETURN
return Handler