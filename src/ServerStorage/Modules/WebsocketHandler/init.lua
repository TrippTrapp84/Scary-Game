--// SERVICES
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// REQUIRES
local Events = require(ReplicatedStorage.Network.Utility.Event)

--// CONSTANTS
local NULL = {}
local UNIQUE_IDENTIFIER = HttpService:GenerateGUID(false)

--// VARIABLES

--// CONSTRUCTOR
local Socket = {}
Socket.__index = Socket

--// SINGLE DESCRIPTION METHODS
local function DefaultValues()
    return {
        url = "http://localhost:8080/v1/websocket",
        websocket_event_name = "websocket_force_update",
        websocket_send_request_name = "websocket_force_request"
    }
end

-- Attempts to request for master status and returns weather it was granted it or not
local function SendMasterRequest(self)
    local response = HttpService:RequestAsync(
        {
            Url = self.url,
            Method = "GET"
        }
    )

    if response.StatusCode ~= 201 then
        return false
    end

    local master_response = HttpService:RequestAsync(
        {
            Url = self.url,
            Method = "GET",
            Headers = {
                ["master-server"] = "true",
                ["rbx-web-socket"] = "true",
                ["rbx-web-socket-id"] = tostring(UNIQUE_IDENTIFIER),
                ["rbx-web-socket-request-id"] = tostring(self.CurrentRequestNumber)
            }
        }
    )

    if master_response.StatusCode ~= 202 then
        return false
    end

    return true
end

-- Makes sure no errors occur
local function RequestMasterStatus(self)
    local success, message = pcall(SendMasterRequest, self)

    if not success then
        error("API is down! Please get it back up!") -- Usually happens when the server is down!
    end

    return message
end

--// NEW
function Socket.new(Data)
    Data = Data or {}
    local Obj = {}
    
    setmetatable(Obj, Socket)

    for i,v in pairs(DefaultValues()) do
        Obj[i] = Data[i] == nil and v or Data[i]
        if Obj[i] == NULL then error("Missing data for Websocket constructor:", i) end
    end

    --// INITIALIZATION
    Obj.Connections = {}
    Obj.CurrentRequestNumber = 1

    Obj.isMasterServer = RequestMasterStatus(Obj)
    
    if (Obj:GetIsMasterServer()) then
        coroutine.wrap(function()
            Obj:KeepAlive()
        end)()
    end

    return Obj
end

--// MEMBER FUNCTIONS
function Socket:GetIsMasterServer()
    return self.isMasterServer
end

-- Keeps the socket alive and calls an event 
function Socket:KeepAlive()
    while true do
        self.CurrentRequestNumber += 1
        local response = HttpService:RequestAsync({
            Url = self.url,
            Method = "GET",
            Headers = {
                ["rbx-web-socket"] = "true",
                ["rbx-web-socket-id"] = tostring(UNIQUE_IDENTIFIER),
                ["rbx-web-socket-request-id"] = tostring(self.CurrentRequestNumber)
            }
        })

        -- if the status code is not a 408 (Request Timeout), then we should examine it else where
        if response.StatusCode ~= 408 then
            -- Fire some event to signify new data may be available
        end
    end
end

--// RETURN
return Socket