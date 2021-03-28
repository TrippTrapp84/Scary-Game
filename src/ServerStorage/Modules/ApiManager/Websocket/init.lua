--// SERVICES
local HttpService = game:GetService("HttpService")

--// REQUIRES

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
        Added_Headers = NULL
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

    coroutine.wrap(function()
        while Obj.IsActive do
            local success, response = Obj:SendRequest()
            if not success then
                -- Send something to the api manager to signify that the api is down currently
                wait(RETRY_PERIOD)
                continue
            end
            
            -- Means that we are no longer called the master in relation to the server. Disables us
            if response.StatusCode == 401 then    
                -- Find if the API manager can get control again, if not begin self destruct
            elseif response.StatusCode == 200 then -- 200 is tenative
                -- Returns the data in a json object in the body. Then we can fire an event from here to handle that data
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
    for key, value in pairs(self.new_headers) do    -- Adds the new headers on top
        headers[key] = headers[key] or value        -- Prevents overwriting
    end

    local success, message = pcall(function()
        local response = HttpService:RequestAsync({
            Url = self.Url,
            Method = "GET",
            Headers = headers,
            Body = body
        })

        return response
    end)

    return success, message
end

--// RETURN
return Socket