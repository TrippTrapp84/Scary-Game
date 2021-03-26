--[[
	Allows the server to listen for events from a client. It will also listen securely for them.
	The network server can be modified to reduce possibility of hacking.

local NetworkServer = referenceTheNetworkServerModule

NetworkServer.listenForPacket("ClientLoadedSuccessfully", function(packet)
	if packet[1] then print("all is loaded") end
end)
]]