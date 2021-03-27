--// SERVICES
local RepStore = game:GetService("ReplicatedStorage")
local RunServ = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

--// REQUIRES

--// CONSTANTS
local NULL = {}
local MOUSE_ENABLED = UIS.MouseEnabled
local TOUCH_ENABLED = UIS.TouchEnabled
local DRAG_DELAY = 0.2

--// VARIABLES
local plr = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local PlrGui = plr:WaitForChild("PlayerGui")

--// LOCAL FUNCTIONS
local function DictSize(Dict)
    local Count = 0
    for _,_ in pairs(Dict) do
        Count += 1
    end
    return Count
end

local function ToScreenScale_Vec2(Pos : Vector2)
    return UDim2.fromScale(Pos.X / Camera.ViewportSize.X,Pos.Y / Camera.ViewportSize.Y)
end

--// TABLES
local InputFunctions = {
    [Enum.UserInputType.MouseButton1] = function(self,input,gameProcessed)
        if self.State.InAction then return end
        self.InAction = true

        local EndCon
        local EndTime = tick()
        local InputEnded = false

        EndCon = UIS.InputEnded:Connect(function(EndInput,EndGP)
            if EndInput.UserInputType == Enum.UserInputType.MouseButton1 then
                InputEnded = true
                EndCon:Disconnect()
                if tick() - EndTime < DRAG_DELAY then
                    self.State.InAction = false
                    print("Grabbing")
                    self:UseCurrentHover(input.Position)
                end
            end
        end)

        local GrabbedUI = self:GetCurrentHover(input.Position)

        wait(DRAG_DELAY)

        if not InputEnded and GrabbedUI then
            local MoveVersion = GrabbedUI:Clone()
            MoveVersion.Size = ToScreenScale_Vec2(GrabbedUI.AbsoluteSize)
            MoveVersion.Parent = PlrGui.Main
            while not InputEnded do
                local MPos = UIS:GetMouseLocation()
                MoveVersion.Position = ToScreenScale_Vec2(MPos)
                RunServ.Heartbeat:Wait()
            end
            MoveVersion:Destroy()
            local DroppedUI = self:GetCurrentHover(UIS:GetMouseLocation())
            if DroppedUI then
                self:MoveItem(tonumber(GrabbedUI.Name),tonumber(DroppedUI.Name))
            end
        end

        self.State.InAction = false
    end,
    [Enum.UserInputType.Keyboard] = function(self,input,gp)
        if self.State.InAction then return end
        local Number
        if input.KeyCode == Enum.KeyCode.One then
            Number = 1
        elseif input.KeyCode == Enum.KeyCode.Two then
            Number = 2
        elseif input.KeyCode == Enum.KeyCode.Three then
            Number = 3
        elseif input.KeyCode == Enum.KeyCode.Four then
            Number = 4
        elseif input.KeyCode == Enum.KeyCode.Five then
            Number = 5
        elseif input.KeyCode == Enum.KeyCode.Six then
            Number = 6
        elseif input.KeyCode == Enum.KeyCode.Seven then
            Number = 7
        elseif input.KeyCode == Enum.KeyCode.Eight then
            Number = 8
        elseif input.KeyCode == Enum.KeyCode.Nine then
            Number = 9
        elseif input.KeyCode == Enum.KeyCode.Zero then
            Number = 10
        else
            return
        end
        self:UseItem(Number)
    end,
    ["TouchTap"] = function(self,Positions,gp)
        if self.State.InAction then return end
        local TappedUI
        for i,v in pairs(Positions) do
            TappedUI = self:GetCurrentHover(v)
            if TappedUI then break end
        end
        if not TappedUI then return end
        self:UseItem(tonumber(TappedUI.Name))
    end,
    ["TouchLongPress"] = {
        [Enum.UserInputState.Begin] = function(self,Positions,State,gp)
            if self.State.InAction then return end
            self.State.InAction = true
            local GrabbedUI
            local GrabbedFingerInd
            for i,v in pairs(Positions) do
                GrabbedUI = self:GetCurrentHover(v)
                if GrabbedUI then GrabbedFingerInd = i break end
            end
            if not GrabbedUI then
                self.State.InAction = false
                return
            end
            local MoveVersion = GrabbedUI:Clone()
            self.State.MoveUI = MoveVersion
            MoveVersion.Size = ToScreenScale_Vec2(GrabbedUI.AbsoluteSize)
            MoveVersion.Parent = PlrGui.Main
            local MPos = Positions[GrabbedFingerInd]
            MoveVersion.Position = ToScreenScale_Vec2(MPos)
        end,
        [Enum.UserInputState.Change] = function(self,Positions,State,gp)
            if not self.State.InAction then return end
            local GrabbedUI = self.State.MoveUI
            if not GrabbedUI then return end
            local GrabbedPosInd
            for i,v in pairs(Positions) do
                if not GrabbedPosInd then GrabbedPosInd = i continue end
                if (Positions[GrabbedPosInd] - GrabbedUI.AbsolutePosition).Magnitude > (v - GrabbedUI.AbsolutePosition).Magnitude then
                    GrabbedPosInd = i
                end
            end
            local MPos = Positions[GrabbedPosInd]
            GrabbedUI.Position = ToScreenScale_Vec2(MPos)
        end,
        [Enum.UserInputState.End] = function(self,Positions,State,gp)
            if not self.State.InAction then return end
            local GrabbedUI = self.State.MoveUI
            local GrabbedPosInd
            for i,v in pairs(Positions) do
                if not GrabbedPosInd then GrabbedPosInd = i continue end
                if (Positions[GrabbedPosInd] - GrabbedUI.AbsolutePosition).Magnitude > (v - GrabbedUI.AbsolutePosition).Magnitude then
                    GrabbedPosInd = i
                end
            end
            local MPos = Positions[GrabbedPosInd]
            local DroppedUI = self:GetCurrentHover(MPos)
            if DroppedUI then
                self:MoveItem(tonumber(GrabbedUI.Name),tonumber(DroppedUI.Name))
            end
            GrabbedUI:Destroy()
            self.State.MoveUI = nil
            self.State.InAction = false
        end
    }
}

--// CONSTRUCTOR
local Handler = {}
Handler.__index = Handler

local function DefaultValues()
    return {
        Size = 9,
        Inventory = {},
        MountFrame = NULL
    }
end

function Handler.new(Data)
    Data = Data or {}
    local Obj = {}

    setmetatable(Obj,Handler)

    for i,v in pairs(DefaultValues()) do
        Obj[i] = Data[i] or v
        if Obj[i] == NULL then error("Missing data " .. i .. " for InventoryHandler constructor") end
    end

    --// INITIALIZATION
    Obj.InventoryCount = DictSize(Obj.Inventory)
    Obj.Connections = {}
    Obj.State = {}
    Obj.State.InAction = false

    local TempInv = Obj.Inventory
    Obj.Inventory = {}
    for i,v in pairs(TempInv) do
       Obj:AddItem(v)
    end

    --// CONNECTIONS

    Obj.Connections[3] = plr.CharacterAdded:Connect(function(char)
        Obj:InitInputConnections()
        Obj.Connections[4] = char:WaitForChild("Humanoid").Died:Connect(function()
            Obj:DisableInventory()
        end)
    end)

    Obj:InitInputConnections()

    return Obj
end

--// DESTRUCTOR
function Handler:Destroy()
    for i,v in pairs(self.Connections) do
        v:Disconnect()
    end
    self:UnequipItem()
    RunServ.Heartbeat:Wait()
    if self.CurrentItem then
        self:UnequipItem()
    end
end

--// MEMBER FUNCTIONS
function Handler:InitInputConnections()
    if MOUSE_ENABLED then
        self.Connections[1] = UIS.InputBegan:Connect(function(input,gp)
            local Function = InputFunctions[input.UserInputType] or InputFunctions[input.KeyCode]
            if not Function then return end
            Function(self,input,gp)
        end)
    elseif TOUCH_ENABLED then
        self.Connections[1] = UIS.TouchLongPress:Connect(function(Positions,State,gp)
            local Func = InputFunctions.TouchLongPress[State]
            if not Func then return end
            Func(self,Positions,State,gp)
        end)

        self.Connections[2] = UIS.TouchTap:Connect(function(Positions,gp)
            InputFunctions.TouchTap(self,Positions,gp)
        end)
    end
end

function Handler:DisableInventory()
    self.Connections[1]:Disconnect()
    if self.Connections[2] then self.Connections[2]:Disconnect() end
    self:UnequipItem()
    RunServ.Heartbeat:Wait()
    if self.CurrentItem then
        self:UnequipItem()
    end
end

function Handler:AddItem(Item)
    for i,v in pairs(self.Inventory) do
        if Item.Name == v.Name then
            if v.Count < v.MaxCount then
                v.Count += 1
                return true
            end
        end
    end

    if self.InventoryCount < self.Size then
        self.InventoryCount += 1
        local Index
        for i = 1,self.Size do
            if not self.Inventory[i] then
                Index = i
                break    
            end
        end
        self.Inventory[Index] = Item
        self.MountFrame[Index%self.Size].Icon.Image = Item.Icon
        return true
    end

    return false
end

function Handler:RemoveItem(Ind)
    local Item = self.Inventory[Ind]
    self.InventoryCount -= Item and 1 or 0
    self.Inventory[Ind] = nil
    Item:Drop(self)
end

function Handler:DestroyItem(Ind)
    local Item = self.Inventory[Ind]
    self.Inventory[Ind] = nil
    Item:Destroy(self)
end

function Handler:UnequipItem()
    if not self.CurrentItem then return end
    self.CurrentItem:Unequip()
    self.CurrentItem = nil
end

function Handler:UseItem(ItemInd)
    if self.CurrentItemInd == ItemInd then return true end
    if self.State.InAction then return false end
    local Item = self.Inventory[ItemInd]
    if not Item then return false end
    self:UnequipItem()
    Item:Equip()
    self.State.InAction = false
    return true
end

function Handler:MoveItem(IndFrom,IndTo)
    local ToTemp = self.Inventory[IndTo]
    self.Inventory[IndTo] = self.Inventory[IndFrom]
    self.Inventory[IndFrom] = ToTemp
    self.MountFrame[IndFrom%self.Size].Icon.Image = self.Inventory[IndFrom] and self.Inventory[IndFrom].Icon or ""
    self.MountFrame[IndTo%self.Size].Icon.Image = self.Inventory[IndTo] and self.Inventory[IndTo].Icon or ""
end

function Handler:GetCurrentHover(Position)
    local GrabbedUI = PlrGui:GetGuiObjectsAtPosition(Position.X,Position.Y)
    local FoundUI
    for i,v in pairs(GrabbedUI) do
        if v.Parent == self.MountFrame then
            FoundUI = v
            break
        end
    end
    return FoundUI
end

function Handler:UseCurrentHover(Position)
    local HoverUI = self:GetCurrentHover(Position)
    if not HoverUI then return end
    return self:UseItem(tonumber(HoverUI.Name))
end

return Handler