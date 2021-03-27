--// SERVICES
local RepStore = game:GetService("ReplicatedStorage")

--// REQUIRES
local InventoryHandler = require(RepStore.Modules.InventoryHandler)

--// VARIABLES
local PlrGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local function Init()

    local Services = {}
    _G.Services = _G.Services or {}
    _G.Services.Client = Services

    Services.Inventoryhandler = InventoryHandler.new{
        Size = 9,
        Inventory = {},
        MountFrame = PlrGui.Menu.InventoryFrame
    }

    return true
end

return Init