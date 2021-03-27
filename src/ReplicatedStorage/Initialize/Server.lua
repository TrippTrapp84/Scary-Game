-- SERVICES
local RepStore = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- REQUIRES
local WebsocketService = require(ServerStorage.Modules.WebsocketService)

-- VARIABLES
local root_api = "http://localhost:8080"

local function Init()

    local Services = {}
    _G.Services = Services

    Services.WebsocketService = WebsocketService.new({
        ["url"] = root_api.. "/v1/websocket"
    })

    return true
end

return Init