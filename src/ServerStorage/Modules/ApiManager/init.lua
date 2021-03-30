--// SERVICES
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MessagingService = game:GetService("MessagingService")

--// REQUIRES
local EVENT_NETWORK = require(ReplicatedStorage.Network.Utility.Event)
local Websocket = require(script.Websocket)

--// CONSTANTS
local NULL = {}
local RETRY_INTERVAL = 10

local EVENT_NAMES = {
    API_NOT_RESPONDING = "websocket_api_not_responding",
    API_LOST_AUTHORIZATION = "websocket_not_authorized",
    WEBSOCKET_GOT_DATA = "websocket_received_data"
}

local MESSAGING_SERVICE_TOPICS = {
    NEW_DATA_RECEIVED = "api_received_data",
    MASTER_TERMINATING = "api_master_server_terminating"
}

--// VARIABLES

--// CONSTRUCTOR
local ApiManager = {}
ApiManager.__index = ApiManager

local function DefaultValues()
    return {
        url = "http://localhost:8080",
        ApiEndpoints = {
            identification_api = "/v1/server/identify",  -- TEMP NAME
            websocket_api = "/v1/websocket", -- Maybe? TEMP NAME
            teminating_api = "/v1/server/terminating"
        }
    }
end

function ApiManager.new(Data)
    Data = Data or {}
    local Obj = {}
    
    setmetatable(Obj, ApiManager)

    for i, v in pairs(DefaultValues()) do
        Obj[i] = Data[i] == nil and v or Data[i]
        if Obj[i] == NULL then error("Missing data for ApiManager constructor:", i) end
    end

    --// INITIALIZATION
    Obj.ServerUUID = HttpService:GenerateGUID(false)

    local success, message = false, NULL

    while not success do
        success, message = pcall(function()
            local response = HttpService:RequestAsync({
                Url = Obj.url.. Obj.ApiEndpoints.identification_api,
                Method = "GET",
                Headers = {
                    ["rbx-game-id"] = tostring(game.GameId),
                    ["rbx-server-id"] = tostring(Obj.ServerUUID)
                }
            })

            Obj.isMasterServer = response.Headers["rbx-master-server"] == "true" and true or false
        end)

        if not success then
            wait(RETRY_INTERVAL)
        end 
    end

    if Obj.isMasterServer then
        Obj:DefineSocketEvents()
        Obj.MasterServerSocket = Websocket.new({
            Url = Obj.url.. Obj.ApiEndpoints.websocket_api,
            Added_Headers = {
                ["rbx-game-id"] = tostring(game.GameId),
                ["rbx-server-id"] = tostring(Obj.ServerUUID)
            },
            EventNames = EVENT_NAMES
        })
    end

    game:BindToClose(function()
        local response = HttpService:RequestAsync({
            Url = Obj.url.. Obj.ApiEndpoints.teminating_api,
            Method = "POST",
            Headers = {
                ["rbx-game-id"] = tostring(game.GameId),
                ["rbx-server-id"] = tostring(Obj.ServerUUID)
            }
        })

        return response
    end)

    return Obj
end

--// MEMBER FUNCTIONS
function ApiManager:DefineSocketEvents()
    -- Calls this function when the client (us) loses the ability to communicate with the api.
    EVENT_NETWORK.listenForPacket(EVENT_NAMES.API_NOT_RESPONDING, function(packet)
        self.ApiOnline = not packet.api_down
    end)
    
    -- Calls this function when the api loses authorization.
    EVENT_NETWORK.listenForPacket(EVENT_NAMES.API_LOST_AUTHORIZATION, function(packet)
        print(packet)
    end)

    -- Calls this function when the websocket gets data back from the api.
    EVENT_NETWORK.listenForPacket(EVENT_NAMES.WEBSOCKET_GOT_DATA, function(packet)
        if (#HttpService:JSONEncode(packet) > 1024) then
            -- JSON element is probably getting to large to transfer.
        end

        MessagingService:PublishAsync(MESSAGING_SERVICE_TOPICS.NEW_DATA_RECEIVED, packet)
    end)
end

--// RETURN
return ApiManager