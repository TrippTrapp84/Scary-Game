--// SERVICES
local DSService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local ServerStorage = game:GetService("ServerStorage")
local RepStore = game:GetService("ReplicatedStorage")
local RunServ = game:GetService("RunService")
local Players = game:GetService("Players")

--//CONSTANTS
local RETRY_COUNT = 3
local RETRY_DELAY = 1
local AUTOSAVE_INTERVAL = 30
local DS_KEY = "flfppsjvfqlepzsedhyg"

--// VARIABLES
local RemoteEvents = RepStore.RemoteEvents.DataEvents
local DataStore = DSService:GetDataStore(DS_KEY)


--// DATA TABLES
local PlayerData = {}
local UnsavedData = {}

local function DefaultData()
    return {
        Currency = 0,
        Inventory = {},
        ActiveQuests = {},
        CompletedQuests = {}
    }
end

--//MEMBER FUNCTIONS
local Handler = {
    PlayerData = PlayerData
}

function Handler:Get(Index,RetryCount)
    RetryCount = RetryCount or RETRY_COUNT
    if RetryCount == 0 then return false end
    local success,data = pcall(function()
        return DataStore:GetAsync(Index)
    end)
    if not success then
        wait(RETRY_DELAY)
        return self:Get(Index,RetryCount - 1)
    else
        return true,data
    end
end

function Handler:Set(Index,Value,RetryCount)
    RetryCount = RetryCount or RETRY_COUNT
    if RetryCount == 0 then return false end
    local success,error = pcall(function()
        DataStore:SetAsync(Index,Value)
    end)
    if not success then
        wait(RETRY_DELAY)
        return self:Set(Index,Value,RetryCount - 1)
    else
        return true
    end
end

function Handler:AddPlayer(Player)
    if UnsavedData[Player.UserId] then
        MessagingService:PublishAsync("PlayerDataBackups",{
            Resolved = true,
            UserId = Player.UserId
        })
        local Data = UnsavedData[Player.UserId]
        PlayerData[Player.UserId] = Data
        return true,Data
    end

    local Success, Data = self:Get(Player.UserId)
    if not Success then
        Player:Kick()
        return false
    end

    Data = Data or DefaultData()
    Data.DefaultData = DefaultData()

    PlayerData[Player.UserId] = Data
    return true,Data
end

function Handler:RemovePlayer(Player)
    local UserId = Player.UserId
    local Data = PlayerData[UserId]
    local Success = self:Set(UserId,Data)
    
    if not Success then
        Data.AutosaveKill = true
        MessagingService:PublishAsync("PlayerDataBackups",{
            Resolved = false,
            UserId = UserId,
            Data = Data
        })
    end
    PlayerData[UserId] = nil
end

function Handler:ParseIndex(Index)
    if not Index then return {} end
    local Inds = string.split("/",Index)
    return Inds
end

function Handler:GetData(PlayerID,Index)
    local Data = PlayerData[PlayerID]
    if not Data then return false end
    local Default = Data.DefaultData
    for _,Ind in pairs(self:ParseIndex(Index)) do
        if Data[Ind] == nil then
            Data[Ind] = Default[Ind]
            if Data[Ind] == nil then return false end
        end
        Default = Default[Ind]
        Data = Data[Ind]
    end
    return true,Data
end

function Handler:SetData(PlayerID,Index,Value)
    local Data = PlayerData[PlayerID]
    if not Data then return false end
    local Default = Data.DefaultData
    local Inds = self:ParseIndex(Index)
    local SetInd = table.remove(Inds,#Inds)
    for _,Ind in pairs(Inds) do
        if Data[Ind] == nil then
            Data[Ind] = Default[Ind]
            if Data[Ind] == nil then return false end
        end
        Default = Default[Ind]
        Data = Data[Ind]
    end
    Data[SetInd] = Value
    return true
end

--// CONNECTIONS
MessagingService:SubscribeAsync("PlayerDataBackups",function(Data,Time)
    if Data.Resolved == true then
        UnsavedData[Data.UserId] = nil
    else
        UnsavedData[Data.UserId] = Data.Data
    end
end)

coroutine.wrap(function()
    while true do
        wait(AUTOSAVE_INTERVAL)
        for i,v in pairs(PlayerData) do
            local Success = Handler:Set(i,v)
            if Success and v.AutosaveKill then
                PlayerData[i] = nil
                MessagingService:PublishAsync("PlayerDataBackups",{
                    Resolved = true,
                    UserId = i
                })
            end
        end
    end
end)()

Players.PlayerAdded:Connect(function(plr)
    Handler:AddPlayer(plr)
end)

Players.PlayerRemoving:Connect(function(plr)
    Handler:RemovePlayer(plr)
end)

RemoteEvents.GetData.OnServerInvoke = function(plr,PlayerID,Index)
    local Success,Data = Handler:GetData(PlayerID,Index)
    print("Called",Success,Data)
    return Success,Data
end

game:BindToClose(function()
    for i,v in pairs(PlayerData) do
        Handler:Set(i,v)
    end
end)


--// RETURN
return Handler