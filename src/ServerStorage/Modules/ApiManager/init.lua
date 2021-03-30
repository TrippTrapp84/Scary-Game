--// SERVICES
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MessagingService = game:GetService("MessagingService")
local RunService = game:GetService("RunService")

--// REQUIRES
local EVENT_NETWORK = require(ReplicatedStorage.Network.Utility.Event)
local Websocket = require(script.Websocket)

--// CONSTANTS
local NULL = {}

local RETRY_INTERVAL = 10
local BIND_TO_CLOSE_TIMEOUT = 5
local BIND_TO_CLOSE_TIMEOUT_STUDIO = 1

-- Names of the events that the event network will use for api
local EVENT_NAMES = {
    API_CONNECTION_STATUS_CHANGED = "websocket_api_connect_status",
    API_AUTHORIZATION_CHANGED = "websocket_authorization_changed",
    WEBSOCKET_GOT_DATA = "websocket_received_data"
}

-- Names of the topics that the messaging service will use for the event network.
local MESSAGING_SERVICE_TOPICS = {
    NEW_DATA_RECEIVED = "api_received_data",
    MASTER_TERMINATING = "api_master_server_terminating",
    MASTER_SERVER_RESPONSE = "api_master_server_response",
    MASTER_SERVER_VALIDATION = "api_master_server_validate"
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

    Obj:DefineSocketEvents()
    Obj:AttemptToClaimMasterServer()

    Obj.MasterServerTerminatingMSEvent = MessagingService:SubscribeAsync(MESSAGING_SERVICE_TOPICS.MASTER_TERMINATING, function(packet)
        if (packet.Data.current_master_id ~= Obj.ServerUUID) then
            MessagingService:PublishAsync(MESSAGING_SERVICE_TOPICS.MASTER_SERVER_RESPONSE, { responder = Obj.ServerUUID })
        end
    end)

    Obj.MasterServerValidationMSEvent = MessagingService:SubscribeAsync(MESSAGING_SERVICE_TOPICS.MASTER_SERVER_VALIDATION, function(packet)
        if (packet.Data.new_master == Obj.ServerUUID) then
            Obj:AttemptToClaimMasterServer()
        end
    end)

    game:BindToClose(Obj:Terminating)

    return Obj
end

--// MEMBER FUNCTIONS //--

-- Connects all of the socket events to the api manager
function ApiManager:DefineSocketEvents()
    -- Calls this function when the client (us) loses the ability to communicate with the api.
    EVENT_NETWORK.listenForPacket(EVENT_NAMES.API_CONNECTION_STATUS_CHANGED, function(packet)
        self.ApiOnline = not packet.api_down
    end)
    
    -- Calls this function when the api loses authorization.
    EVENT_NETWORK.listenForPacket(EVENT_NAMES.API_AUTHORIZATION_CHANGED, function(packet)
        if (packet.authorized or packet.initial_attempt) then
            return
        end

        self:AttemptToClaimMasterServer()
    end)

    -- Calls this function when the websocket gets data back from the api.
    EVENT_NETWORK.listenForPacket(EVENT_NAMES.WEBSOCKET_GOT_DATA, function(packet)
        if (#HttpService:JSONEncode(packet) > 1024) then
            -- JSON element is to large to transfer over messaging service
            print("Data was found to be to large for the messaging service to handle.")
            return;
        end

        MessagingService:PublishAsync(MESSAGING_SERVICE_TOPICS.NEW_DATA_RECEIVED, packet)
    end)
end

-- Allows the API Manager to attempt to gain privileges 
function ApiManager:CheckForAuthorization()
    local success, message = false, NULL

    while not success do
        -- Attempts to connect to the API
        success, message = pcall(function()
            local response = HttpService:RequestAsync({
                Url = self.url.. self.ApiEndpoints.identification_api,
                Method = "GET",
                Headers = {
                    ["rbx-game-id"] = tostring(game.GameId),
                    ["rbx-server-id"] = tostring(self.ServerUUID)
                }
            })

            self.isMasterServer = response.Headers["rbx-master-server"] == "true" and true or false
        end)

        -- If the api is not loading than wait and retry the connection.
        if not success then
            wait(RETRY_INTERVAL)
        end 

        -- Determines if the api is on.
        self.ApiOnline = success
    end

    return self.isMasterServer
end

-- Attempts to claim the master server position, returns true if it did get it.
function ApiManager:AttemptToClaimMasterServer()
    self.isMasterServer = self:CheckForAuthorization()

    if self.isMasterServer then
        self.MasterServerSocket = Websocket.new({
            Url = self.url.. self.ApiEndpoints.websocket_api,
            Added_Headers = {
                ["rbx-game-id"] = tostring(game.GameId),
                ["rbx-server-id"] = tostring(self.ServerUUID)
            },
            EventNames = EVENT_NAMES
        })
    end

    return self.isMasterServer
end

-- Called when terminating the server
function ApiManager:Terminating()
    self.MasterServerTerminatingMSEvent:Disconnect()
    self.MasterServerValidationMSEvent:Disconnect()

    local success, _ = pcall(function()
        local response = HttpService:RequestAsync({
            Url = self.url.. self.ApiEndpoints.teminating_api,
            Method = "POST",
            Headers = {
                ["rbx-game-id"] = tostring(game.GameId),
                ["rbx-server-id"] = tostring(self.ServerUUID)
            }
        })
        return response
    end)
    
    if not self.isMasterServer then
        return
    end

    local responder = nil
    MessagingService:SubscribeAsync(MESSAGING_SERVICE_TOPICS.MASTER_SERVER_RESPONSE, function(packet)
        if (packet.Data.responder ~= self.ServerUUID) then
            responder = packet.Data.responder
        end
    end)
    MessagingService:PublishAsync(MESSAGING_SERVICE_TOPICS.MASTER_TERMINATING, { master_terminating = true, current_master_id = self.ServerUUID })

    local counter = 0
    repeat counter += wait() until responder or counter >= (RunService:IsStudio() and BIND_TO_CLOSE_TIMEOUT_STUDIO or BIND_TO_CLOSE_TIMEOUT)

    if responder then
        MessagingService:PublishAsync(MESSAGING_SERVICE_TOPICS.MASTER_SERVER_VALIDATION, { new_master = responder })
    end
end

--// RETURN
return ApiManager