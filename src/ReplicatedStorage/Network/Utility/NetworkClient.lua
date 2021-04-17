--Services
local NetworkFolder   = game.ReplicatedStorage:WaitForChild("Network")
--Locals
local NetworkSocket       = NetworkFolder.NetworkSocket
local RemoteFunction      = NetworkFolder.RemoteFunction
local internal_functions  = {}

--Module
local Network = {}

--Function to create a packet listener, calls the callback once the identifier matches the signal sent from the server
function Network.listenForPacket(identifier, callback)
	-- connect socket
	return NetworkSocket.OnClientEvent:Connect(function(newIdentifier, packet)
		-- ensure the ids match
		if (identifier:lower():match(newIdentifier:lower()) ~= nil) then
			-- call callback with packet, and ids
			callback(packet, identifier, newIdentifier)
		end
	end)
end

--Function to yield until a signal has been sent from the server that corresponds with the identifier
function Network.waitForPacket(identifier)
	-- loop to yield
	while true do 
		wait()
		-- wait to return id and packet once the signal has been received
		local newIdentifier, packet = NetworkSocket.OnClientEvent:Wait()
		-- ensure the ids match
		if (identifier:lower():match(newIdentifier:lower()) ~= nil) then
			-- return the packet and ids
			return packet, identifier, newIdentifier
		end
	end
end

--Function to send a signal to the server with the corresponding packet and id
function Network.sendPacket(identifier, packet)
	NetworkSocket:FireServer(identifier, packet)
end

--Function to invoke server and wait for a response, function yields
function Network.invokeServerAsync(identifier, packet, callback)
	-- invoke the server and return our packet
	local returnedPacket = RemoteFunction:InvokeServer(identifier, packet)
	 
	-- if our return value is not nil then we can call the callback
	if returnedPacket then
		-- we may want to just return the returned value as opposed to calling a function with the returned value
		if callback ~= nil then
			callback(returnedPacket, identifier)
		else
			return returnedPacket
		end
	else
		--warn the client of a nil value being returned
		warn("Packet returned nil, under identifier: "..identifier)
	end
end

--Function to listen for when the client is invoked from the server
function Network.onClientInvoke(identifier, callback)
	-- cache the callback function with its respective identifier
	internal_functions[identifier] = callback
end

--Function to call any callbacks when invoked
function RemoteFunction.OnClientInvoke(identifier, packet)
	-- verify the exitence of the call back
	if  internal_functions[identifier] then
		-- call it
		return internal_functions[identifier](packet, identifier)
	end
end

return Network
