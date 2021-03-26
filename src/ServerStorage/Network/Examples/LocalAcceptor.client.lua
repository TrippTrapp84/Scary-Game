--[[
	Used for client to client communication.

local NetworkClient = referenceTheNetworkClientModule
local EventModule   = referenceEventModule

EventModule.listenForPacket("LoadModules", function(packet)
	if packet[1] then NetworkClient.sendPacket("ModulesLoadedSuccessfully", packet) end
end)
]]