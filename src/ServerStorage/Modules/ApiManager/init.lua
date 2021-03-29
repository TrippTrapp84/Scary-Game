--// SERVICES
local HttpService = game:GetService("HttpService")

--// REQUIRES
local Websocket = require(script.Websocket)

--// CONSTANTS
local NULL = {}
local RETRY_INTERVAL = 10

--// VARIABLES

--// CONSTRUCTOR
local ApiManager = {}
ApiManager.__index = ApiManager

local function DefaultValues()
    return {
        url = "http://localhost:8080",
        identification_api = "/v1/server/identify",  -- TEMP NAME
        websocket_api = "/v1/websocket", -- Maybe? TEMP NAME
        teminating_api = "/v1/server/terminating"
    }
end

function ApiManager.new(Data)
    Data = Data or {}
    local Obj = {}
    
    setmetatable(Obj,ApiManager)

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
                Url = Obj.url.. Obj.identification_api,
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
        Obj.MasterServerSocket = Websocket.new({
            Url = Obj.url.. Obj.websocket_api,
            Added_Headers = {
                ["rbx-game-id"] = tostring(game.GameId),
                ["rbx-server-id"] = tostring(Obj.ServerUUID)
            }
        })
    end

    game:BindToClose(function()
        local response = HttpService:RequestAsync({
            Url = Obj.url.. Obj.teminating_api,
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

--// RETURN
return ApiManager