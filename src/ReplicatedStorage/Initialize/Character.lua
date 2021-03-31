local RepStore = game:GetService("ReplicatedStorage")

local CameraManager = require(RepStore.Modules.Camera)
local PlayerManager = require(RepStore.Modules.PlayerManager)

local PLAYER = game:GetService("Players").LocalPlayer
local CAMERA = workspace.CurrentCamera

local function Init()
    
    local CHARACTER = PLAYER.Character or PLAYER.CharacterAdded:Wait()

    local Services = {}
    _G.Services = _G.Services or {}
    _G.Services.Character = Services

    Services.CameraHandler = CameraManager.new{
        Player = PLAYER,
        Character = CHARACTER,
        Camera = CAMERA
    }

    Services.PlayerManager = PlayerManager.new{
        Player = PLAYER,
        Character = CHARACTER,
        InitialState = "Idle"
    }

    return true
end

return Init