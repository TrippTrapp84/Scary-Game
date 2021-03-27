local RepStore = game:GetService("ReplicatedStorage")

local function Init()

    local Services = {}
    _G.Services = _G.Services or {}
    _G.Services.Character = Services

    return true
end

return Init