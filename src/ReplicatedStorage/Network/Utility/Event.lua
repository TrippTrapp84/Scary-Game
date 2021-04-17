--Services
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Network")
--Locals
local event       = {}
local eventObject = Shared.Event

--Event listener receives the arguments <string : packetType, function : callback>
function event.listenForPacket(packetType, callback)
	--Return the event listener
	return eventObject.Event:Connect(function(newPacketType, packet)
		--ensure the packetType we're listening for is the one returned by the listener event
		if (newPacketType:upper():match(packetType:upper()) ~= nil) then
			--Call the callback
			callback(packet, newPacketType, packetType)
		end
	end)
end

--Event yielding, we wait for the packet, receives the arguments <string : packetType>
function event.waitForPacket(packetType)
	--yield until we receive the packet
	while true do
		--Wait for the event
		local newPacketType, packet = eventObject.Event:wait()
		--If it matches what we want, return the packet
		if (newPacketType:upper():match(packetType:upper()) ~= nil) then
			return packet, newPacketType, packetType
		end
	end
	return
end

--Event firing, we send the packet with the specified packet type, receives the arguments <string : packetType, array : packet>
function event.sendPacket(packetType, packet)
	eventObject:Fire(packetType, packet)
end

--Return these functions
return event
