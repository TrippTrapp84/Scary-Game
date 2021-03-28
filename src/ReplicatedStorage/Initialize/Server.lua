-- SERVICES
local RepStore = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- REQUIRES
local ApiManager = require(ServerStorage.Modules.ApiManager)

-- CONSTANTS
local ROOT_API = "http://localhost:8080"

-- VARIABLES


local function Init()

    local Services = {}
    _G.Services = Services

    Services.ApiManager = ApiManager.new({
        url = ROOT_API,
        new_connections_api = "/v1/new_server",  -- TEMP NAME
        websocket_api = "/v1/websocket" -- Maybe? TEMP NAME
    })

    return true
end

return Init