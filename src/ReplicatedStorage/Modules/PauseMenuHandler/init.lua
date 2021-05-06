--// SERVICES
local UIS = game:GetService("UserInputService")
local RepStore = game:GetService("ReplicatedStorage")
local Services = _G.Services

--// REQUIRES

--// CONSTANTS
local NULL = {}

--// VARIABLES
local Assets = RepStore.Assets

--// CONSTRUCTOR
local Handler = {}
Handler.__index = Handler

local function DefaultValues()
    return {
        Open = false,
        MountFrame = NULL
    }
end

function Handler.new(Data)
    Data = Data or {}
    local Obj = {}
    
    setmetatable(Obj,Handler)

    for i,v in pairs(DefaultValues()) do
        Obj[i] = Data[i] == nil and v or Data[i]
        if Obj[i] == NULL then error("Missing data for PauseMenuHandler constructor:",i) end
    end

    --// INITIALIZATION
    Obj.MenuConnections = {}

    Obj.Connections = {}

    do --// INITIAL
        Obj.Connections[1] = Obj.MountFrame.Initial.Credits.Button.Activated:Connect(function()
            Obj.MountFrame.Initial.Visible = false
            Obj.MountFrame.Initial_Credits.Visible = true
            Obj.MountFrame.Initial_Credits_SideMenu.Visible = true
        end)
        Obj.Connections[2] = Obj.MountFrame.Initial.Help.Button.Activated:Connect(function()
            Obj.MountFrame.Initial.Visible = false
            Obj.MountFrame.Initial_Help.Visible = true
            Obj.MountFrame.Initial_Help_SideMenu.Visible = true
        end)
        Obj.Connections[3] = Obj.MountFrame.Initial.Settings.Button.Activated:Connect(function()
            Obj.MountFrame.Initial.Visible = false
            Obj.MountFrame.Initial_Settings.Visible = true
            Obj.MountFrame.Initial_Settings_SideMenu.Visible = true
        end)
        Obj.Connections[4] = Obj.MountFrame.Initial.SocialLinks.Button.Activated:Connect(function()
            Obj.MountFrame.Initial.Visible = false
            Obj.MountFrame.Initial_SocialLinks.Visible = true
            Obj.MountFrame.Initial_SocialLinks_SideMenu.Visible = true
        end)
    end

    do --// INITIAL_CREDITS
        Obj.Connections[5] = Obj.MountFrame.Initial_Credits.Back.Button.Activated:Connect(function()
            Obj.MountFrame.Initial_Credits.Visible = false
            Obj.MountFrame.Initial_Credits_SideMenu.Visible = false
            Obj.MountFrame.Initial.Visible = true
        end)
    end

    do --// INITIAL_HELP
        Obj.Connections[6] = Obj.MountFrame.Initial_Help.Back.Button.Activated:Connect(function()
            Obj.MountFrame.Initial_Help.Visible = false
            Obj.MountFrame.Initial_Help_SideMenu.Visible = false
            Obj.MountFrame.Initial.Visible = true
        end)
        Obj.Connections[7] = Obj.MountFrame.Initial_Help.FAQ.Button.Activated:Connect(function()
            Obj.MountFrame.Initial_Help_SideMenu.Gameplay_SideMenu.Visible = false
            Obj.MountFrame.Initial_Help_SideMenu.FAQ_SideMenu.Visible = true
        end)
        Obj.Connections[8] = Obj.MountFrame.Initial_Help.Gameplay.Button.Activated:Connect(function()
            Obj.MountFrame.Initial_Help_SideMenu.FAQ_SideMenu.Visible = false
            Obj.MountFrame.Initial_Help_SideMenu.Gameplay_SideMenu.Visible = true
        end)
    end

    do --// INITIAL_SETTINGS
        Obj.Connections[9] = Obj.MountFrame.Initial_Settings.Back.Button.Activated:Connect(function()
            Obj.MountFrame.Initial_Settings.Visible = false
            Obj.MountFrame.Initial_Settings_SideMenu.Visible = false
            Obj.MountFrame.Initial.Visible = true
        end)
        Obj.Connections[10] = Obj.MountFrame.Initial_Settings.Audio.Button.Activated:Connect(function()
            Obj.MountFrame.Initial_Settings_SideMenu.Controls_SideMenu.Visible = false
            Obj.MountFrame.Initial_Settings_SideMenu.Video_SideMenu.Visible = false
            Obj.MountFrame.Initial_Settings_SideMenu.Audio_SideMenu.Visible = true
        end)
        Obj.Connections[11] = Obj.MountFrame.Initial_Settings.Controls.Button.Activated:Connect(function()
            Obj.MountFrame.Initial_Settings_SideMenu.Audio_SideMenu.Visible = false
            Obj.MountFrame.Initial_Settings_SideMenu.Video_SideMenu.Visible = false
            Obj.MountFrame.Initial_Settings_SideMenu.Controls_SideMenu.Visible = true
        end)
        Obj.Connections[12] = Obj.MountFrame.Initial_Settings.Video.Button.Activated:Connect(function()
            Obj.MountFrame.Initial_Settings_SideMenu.Audio_SideMenu.Visible = false
            Obj.MountFrame.Initial_Settings_SideMenu.Controls_SideMenu.Visible = false
            Obj.MountFrame.Initial_Settings_SideMenu.Video_SideMenu.Visible = true
        end)
    end

    do --// INITIAL_SOCIALLINKS
        Obj.Connections[13] = Obj.MountFrame.Initial_SocialLinks.Back.Button.Activated:Connect(function()
            Obj.MountFrame.Initial_SocialLinks.Visible = false
            Obj.MountFrame.Initial_SocialLinks_SideMenu.Visible = false
            Obj.MountFrame.Initial.Visible = true
        end)
    end

    return Obj
end

--// MEMBER FUNCTIONS
function Handler:TogglePaused(Paused)
    if self.Open == Paused then return end
    if Paused then
        Services.Character.CameraHandler:SetMouseBehavior(Enum.MouseBehavior.Default)
        self.MountFrame.Visible = true
        
    else
        Services.Character.CameraHandler:SetMouseBehavior(Enum.MouseBehavior.LockCenter)
        self.MountFrame.Visible = false
        for i,v in pairs(self.MenuConnections) do
            v:Disconnect()
            self.MenuConnections[i] = nil
        end
    end
end



--// RETURN
return Handler