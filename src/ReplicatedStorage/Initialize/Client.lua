--// SERVICES
local RepStore = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
_G.Services = _G.Services or {}

--// REQUIRES
local Teaser = require(RepStore.Modules.Teaser)
local InventoryHandler = require(RepStore.Modules.InventoryHandler)
local FootprintHandler = require(RepStore.Modules.FootprintHandler)
local PauseMenuHandler = require(RepStore.Modules.PauseMenuHandler)

--// VARIABLES
local Menu = game.Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Menu")

local function Init()

    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat,false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu,false)

    local Services = {}
    _G.Services.Client = Services

    Teaser.new()

    Services.Inventoryhandler = InventoryHandler.new{
        Size = 10,
        Inventory = {},
        MountFrame = Menu.InventoryFrame
    }

    Services.FootprintHandler = FootprintHandler.new{
        
    }

    Services.PauseMenuHandler = PauseMenuHandler.new{
        MountFrame = Menu:WaitForChild("PauseMenu")
    }

    return true
end

return Init