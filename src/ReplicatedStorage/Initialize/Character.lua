local RepStore = game:GetService("ReplicatedStorage")

_G.Services = _G.Services or {}

local CameraManager = require(RepStore.Modules.CameraHandler)
local PlayerManager = require(RepStore.Modules.PlayerManager)
local InteractionHandler = require(RepStore.Modules.InteractionHandler)

local Assets = RepStore:WaitForChild("Assets")

local PLAYER = game:GetService("Players").LocalPlayer
local CAMERA = workspace.CurrentCamera

local function Init()
    
    local CHARACTER = PLAYER.Character or PLAYER.CharacterAdded:Wait()

    local Services = {}
    _G.Services.Character = Services

    Services.CameraHandler = CameraManager.new{
        Player = PLAYER,
        Character = CHARACTER,
        Camera = CAMERA
    }

    Services.PlayerManager = PlayerManager.new{
        Player = PLAYER,
        Character = CHARACTER
    }

    Services.InteractionHandler = InteractionHandler.new{
        Character = CHARACTER
    }

    return true
end

return Init