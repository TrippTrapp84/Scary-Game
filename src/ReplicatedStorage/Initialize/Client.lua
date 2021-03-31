--// SERVICES
local RepStore = game:GetService("ReplicatedStorage")

--// REQUIRES
local Teaser = require(RepStore.Modules.Teaser)
local InventoryHandler = require(RepStore.Modules.InventoryHandler)
local FootprintHandler = require(RepStore.Modules.FootprintHandler)

--// VARIABLES
local Menu = game.Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Menu")

local function Init()

    local Services = {}
    _G.Services = _G.Services or {}
    _G.Services.Client = Services

    Teaser.new()

    Services.Inventoryhandler = InventoryHandler.new{
        Size = 10,
        Inventory = {},
        MountFrame = Menu.InventoryFrame
    }

    Services.FootprintHandler = FootprintHandler.new{
        
    }

    return true
end

return Init