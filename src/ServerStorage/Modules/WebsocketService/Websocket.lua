--// SERVICES
local HttpService = game:GetService("HttpService")

--// REQUIRES

--// CONSTANTS
local NULL = {}
local UNIQUE_IDENTIFIER = HttpService:GenerateGUID(false)

--// VARIABLES
local url = "http://localhost:8080/v1/websocket"

--// CONSTRUCTOR
local Socket = {}
Socket.__index = Socket

--// SINGLE DESCRIPTION METHODS
local function DefaultValues()
    return {

    }
end

-- Attempts to request for master status and returns weather it was granted it or not
local function SendMasterRequest(self)
    local response = HttpService:RequestAsync(
        {
            Url = url,
            Method = "GET"
        }
    )

    if response.StatusCode ~= 201 then
        return false
    end

    local master_response = HttpService:RequestAsync(
        {
            Url = url,
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
        error(message)
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
    Obj.CurrentRequestNumber += 1

    return Obj
end

--// MEMBER FUNCTIONS
function Socket:IsMasterServer()
    return self.isMasterServer
end

--// RETURN
return Socket