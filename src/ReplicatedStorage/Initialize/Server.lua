-- SERVICES
local RepStore = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- REQUIRES
local WebsocketService = require(ServerStorage.Modules.WebsocketService)

-- VARIABLES


local function Init()

    local Services = {}
    _G.Services = Services

    Services.WebsocketService = WebsocketService.new( { } )

    return true
end

return Init