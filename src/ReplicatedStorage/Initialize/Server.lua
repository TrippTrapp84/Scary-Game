-- SERVICES
local RepStore = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- REQUIRES
local WebsocketHandler = require(ServerStorage.Modules.WebsocketHandler)

-- CONSTANTS
local ROOT_API = "http://localhost:8080"

-- VARIABLES


local function Init()

    local Services = {}
    _G.Services = Services

    Services.WebsocketHandler = WebsocketHandler.new({
        url = ROOT_API.. "/v1/websocket",
        websocket_event_name = "websocket_force_update",
        websocket_send_request_name = "websocket_force_request"
    })

    return true
end

return Init