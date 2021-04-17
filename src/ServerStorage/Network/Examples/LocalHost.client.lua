--[[ 
	This example is responsible for sending a client loaded event and
	firing the load modules event to the client.

local NetworkClient = referenceTheNetworkClientModule
local EventModule   = referenceEventModule

NetworkClient.sendPacket("ClientLoadedSuccessfully", {true})
EventModule.sendPacket("LoadModules", {true})

]]