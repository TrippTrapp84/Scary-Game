--// SERVICES
local RepStore = game:GetService("ReplicatedStorage")

--// REQUIRES
local InventoryHandler = require(RepStore.Modules.InventoryHandler)

--// VARIABLES
local Menu = game.Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Menu")

local function Init()

    local Services = {}
    _G.Services = _G.Services or {}
    _G.Services.Client = Services

    Services.Inventoryhandler = InventoryHandler.new{
        Size = 10,
        Inventory = {},
        MountFrame = Menu.InventoryFrame
    }

    return true
end

return Init