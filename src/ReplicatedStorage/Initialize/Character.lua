local RepStore = game:GetService("ReplicatedStorage")
local RunServ = game:GetService("RunService")

local CameraManager = require(RepStore.Camera)

local PLAYER = game:GetService("Players").LocalPlayer
local CHARACTER = PLAYER.Character or PLAYER.CharacterAdded:Wait()
local CAMERA = workspace.CurrentCamera

local function Init()

    local Services = {}
    _G.Services = _G.Services or {}
    _G.Services.Character = Services

    Services.CameraHandler = CameraManager.new{
        Player = PLAYER,
        Character = CHARACTER,
        Camera = CAMERA
    }

    return true
end

return Init