--// SERVICES
local Services = _G.Services

--// REQUIRES

--// INTERACTION FUNCTION
local function Interacted(InteractionSet) --// Called when a user interacts with an interactable that has this script marked as it's designated handler
    local Count= 0
    local InterruptTriggered = false
    local StateChangedCon
    StateChangedCon = Services.Character.PlayerManager.OnStateChanged:Connect(function(OldState,NewState)
        InterruptTriggered = true
        StateChangedCon:Disconnect()
    end)
    repeat
        print("Interacting...")
        Count += 1

        if InterruptTriggered then
            print("Broken!")
            return false
        end

        wait()
    until Count == 30
    if StateChangedCon then StateChangedCon:Disconnect() end
    return true
end

--// RETURN
return Interacted