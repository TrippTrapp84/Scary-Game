--// SERVICES

--// REQUIRES

--// CONSTANTS
local NULL = {}

--// VARIABLES
local Mouse = game.Players.LocalPlayer:GetMouse()
local MouseIcon = Mouse.Icon

--// CONSTRUCTOR
local Handler = {}
Handler.__index = Handler

local function DefaultValues()
    return {

    }
end

function Handler.new(Data)
    Data = Data or {}
    local Obj = {}
    
    setmetatable(Obj,Handler)

    for i,v in pairs(DefaultValues()) do
        Obj[i] = Data[i] == nil and v or Data[i]
        if Obj[i] == NULL then error("Missing data for Teaser constructor:",i) end
    end

    --// INITIALIZATION
    game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

    local UI = game.Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Teaser")
    local Menu = game.Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Menu")
    
    repeat
        wait()
    until game:IsLoaded()

    if not game:GetService("RunService"):IsStudio() then
        wait(.1)
        Menu.Enabled = false
        UI.Enabled = true
        UI.Sound:Play()
        Mouse.Icon = "rbxassetid://0"
        UI.Frame.Logo.ImageTransparency = 1
        UI.Frame.Logo.TextLabel.TextTransparency = 1
        wait(.1)
        for i = 0,1, .02 do
            local t = 1 - i
            wait()
            UI.Frame.Logo.ImageTransparency = t
            UI.Frame.Logo.TextLabel.TextTransparency = t
        end
        wait(2)
        for i = 0,1, .02 do
            wait()
            UI.Frame.Logo.ImageTransparency = i
            UI.Frame.Logo.TextLabel.TextTransparency = i
        end
        UI.Frame.Logo.ImageTransparency = 1
        UI.Frame.Logo.TextLabel.TextTransparency = 1
        wait(1)
        for i = 0,1, .02 do
            wait()
            UI.Frame.BackgroundTransparency = i
        end
        UI.Frame.BackgroundTransparency = 1
        UI.Enabled = false
        game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
        Menu.Enabled = true
        Mouse.Icon = MouseIcon
    end

    return Obj
end

--// MEMBER FUNCTIONS

--// RETURN
return Handler