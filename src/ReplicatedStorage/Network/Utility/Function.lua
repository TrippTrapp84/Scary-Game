--Locals
local funct              = {}
local internal_functions = {}

function funct.listenForPacket(packetType, callback)
	if internal_functions[packetType:lower()] then
		warn("A function with that name already exists. It's being overwriten."..
			" If this was not the intended action, please pick a different name for this listener")
	end
	internal_functions[packetType:lower()] = callback
end

function funct.sendPacket(packetType, packet)
	if internal_functions[packetType:lower()] == nil then
		local msg = packetType:lower().. " has no location to go!"
		warn(msg)
	else
		return internal_functions[packetType:lower()](packet, packetType)	
	end
end

--Return these functions
return funct