--// SERVICES
local RunServ = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

--// REQUIRES

--// CONSTANTS

--// VARIABLES
local StateSwitchFunctions = {}

--// FUNCTIONS
function StateSwitchFunctions.Idle___Slow_Vaulting(PlayerManager)
	
end

function StateSwitchFunctions.Idle___Pause(PlayerManager)
	
end

function StateSwitchFunctions.Idle___PerformingAction(PlayerManager)
	
end

function StateSwitchFunctions.Idle___Damaged(PlayerManager)
	
end

function StateSwitchFunctions.Idle___Running(PlayerManager)
    print("Idle.Run")
	PlayerManager:ToggleMovement(true)
end

function StateSwitchFunctions.Idle___Walking(PlayerManager)
    print("Idle.Walk")
    PlayerManager:ToggleMovement(false)
end

function StateSwitchFunctions.Pause_Damaged___Pause(PlayerManager)
	
end

function StateSwitchFunctions.Pause_Damaged___Dead(PlayerManager)
	
end

function StateSwitchFunctions.Damaged___Idle(PlayerManager)
	
end

function StateSwitchFunctions.Damaged___Dead(PlayerManager)
	
end

function StateSwitchFunctions.Slow_Vaulting___Idle(PlayerManager)
	
end

function StateSwitchFunctions.PerformingAction___Idle(PlayerManager)
	
end

function StateSwitchFunctions.PerformingAction___Damaged(PlayerManager)
	
end

function StateSwitchFunctions.Running___Fast_Vaulting(PlayerManager)
	
end

function StateSwitchFunctions.Running___Idle(PlayerManager)
    print("Run.Idle")
	PlayerManager:ToggleIdleState()
end

function StateSwitchFunctions.Running___PerformingAction(PlayerManager)
	
end

function StateSwitchFunctions.Running___Damaged(PlayerManager)
	
end

function StateSwitchFunctions.Running___Pause(PlayerManager)
	
end

function StateSwitchFunctions.Running___Walking(PlayerManager)
    print("Run.Walk")
	PlayerManager:ToggleMovement(false)
end

function StateSwitchFunctions.Walking___slow_Vaulting(PlayerManager)
	
end

function StateSwitchFunctions.Walking___Idle(PlayerManager)
    print("Walk.Idle")
    PlayerManager:ToggleIdleState()
end

function StateSwitchFunctions.Walking___Pause(PlayerManager)
	
end

function StateSwitchFunctions.Walking___Damaged(PlayerManager)
	
end

function StateSwitchFunctions.Walking___Running(PlayerManager)
    print("Walk.Run")
	PlayerManager:ToggleMovement(true)
end

function StateSwitchFunctions.Walking___PerformingAction(PlayerManager)
	
end

function StateSwitchFunctions.Fast_Vaulting___Running(PlayerManager)
	PlayerManager:ToggleMovement(true)
end

function StateSwitchFunctions.Ghosting___Idle(PlayerManager)
	
end

function StateSwitchFunctions.Pause___Pause_Damaged(PlayerManager)
	
end

function StateSwitchFunctions.Pause___Idle(PlayerManager)
	
end

function StateSwitchFunctions.Dead___Ghosting(PlayerManager)
	
end

--// RETURN
return StateSwitchFunctions