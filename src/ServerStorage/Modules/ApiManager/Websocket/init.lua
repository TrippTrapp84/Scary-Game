--// SERVICES
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// REQUIRES
local EVENT_NETWORK = require(ReplicatedStorage.Network.Utility.Event)

--// CONSTANTS
local NULL = {}
local RETRY_PERIOD = 10

--// VARIABLES

--// CONSTRUCTOR
local Socket = {}
Socket.__index = Socket

local function DefaultValues()
    return {
        Url = NULL,
        Added_Headers = NULL,
        EventNames = {
            API_NOT_RESPONDING = "websocket_api_not_responding",
            API_LOST_AUTHORIZATION = "websocket_not_authorized",
            WEBSOCKET_GOT_DATA = "websocket_received_data"
        }        
    }
end

function Socket.new(Data)
    Data = Data or {}
    local Obj = {}
    
    setmetatable(Obj,Socket)

    for i, v in pairs(DefaultValues()) do
        Obj[i] = Data[i] == nil and v or Data[i]
        if Obj[i] == NULL then error("Missing data for Websocket constructor:", i) end
    end

    --// INITIALIZATION
    Obj.SocketUUID = HttpService:GenerateGUID(false)
    Obj.CurrentRequestNumber = 0

    Obj.IsAuthed = true
    Obj.IsAPIDown = false

    coroutine.wrap(function()
        while Obj.IsAuthed do
            local success, response = Obj:SendRequest()
            if not success then

                if not Obj.IsAPIDown then
                    -- Send something to the api manager to signify that the api is down currently
                    EVENT_NETWORK.sendPacket(Obj.EventNames.API_NOT_RESPONDING, { api_down = true })
                    Obj.IsAPIDown = true
                end

                wait(RETRY_PERIOD)
                continue
            end
            
            -- If the server was previously down and now is back up we send the API manager a message saying we got control again
            if Obj.IsAPIDown then
                EVENT_NETWORK.sendPacket(Obj.EventNames.API_NOT_RESPONDING, { api_down = false })
                Obj.IsAPIDown = false
            end

            -- Means that we are no longer called the master in relation to the server. Disables us
            if response.StatusCode == 401 then    
                EVENT_NETWORK.sendPacket(Obj.EventNames.API_LOST_AUTHORIZATION, { authorized = false })
                Obj.IsAuthed = false
            elseif response.StatusCode == 200 then -- 200 is tenative
                -- Returns the data in a json object in the body. Then we can fire an event from here to handle that data 
                local isValid, json_data = pcall(function() HttpService:JSONDecode(response.Body) end)
                if isValid then
                    EVENT_NETWORK.sendPacket(Obj.EventNames.WEBSOCKET_GOT_DATA, json_data)
                end
            end
        end
    end)()

    return Obj
end

--// MEMBER FUNCTIONS
function Socket:SendRequest(body, new_headers)
    body = body or ""
    new_headers = new_headers or {}

    self.CurrentRequestNumber += 1
    
    local headers = {
        ["rbx-web-socket"] = "true",
        ["rbx-web-socket-id"] = tostring(self.SocketUUID),
        ["rbx-web-request-number"] = tostring(self.CurrentRequestNumber)
    }
    for key, value in pairs(self.Added_Headers) do  -- Adds the constructor headers on top
        headers[key] = headers[key] or value        -- Prevents overwriting
    end
    for key, value in pairs(new_headers) do    -- Adds the new headers on top
        headers[key] = headers[key] or value        -- Prevents overwriting
    end

    local success, message = pcall(function()
        local response = HttpService:RequestAsync({
            Url = self.Url,
            Method = "POST",
            Headers = headers,
            Body = body
        })

        return response
    end)

    return success, message
end

--// RETURN
return Socket