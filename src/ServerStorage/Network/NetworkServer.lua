--Services
local ReplicatedStorage   = game.ReplicatedStorage:WaitForChild("Network")

--Locals
local NetworkSocket       = ReplicatedStorage.NetworkSocket
local RemoteFunction      = ReplicatedStorage.RemoteFunction
local internal_functions  = {}

--Module
local Network = {}

--Function to create a packet listener, calls the callback once the identifier matches the signal sent from the client
function Network.listenForPacket(identifier, callback)
	-- connect socket
	return NetworkSocket.OnServerEvent:Connect(function(player, newIdentifier, packet)
		-- ensure the ids match
		if (identifier:lower():match(newIdentifier:lower()) ~= nil) then
			-- call callback 
			callback(player, packet, identifier, newIdentifier)
		end
	end)
end

--Function to yield until a signal has been sent from the client that corresponds with the identifier
function Network.waitForPacket(identifier)
	-- loop to yield
	while true do 
		wait()
		-- wait to return id and packet once the signal has been received
		local player, newIdentifier, packet = NetworkSocket.OnServerEvent:Wait()
		-- ensure the ids match
		if (identifier:lower():match(newIdentifier:lower()) ~= nil) then
			-- return the packet and ids
			return player, packet, identifier, newIdentifier
		end
	end
end

--Function to send a signal to the corresponding client given the packet and id
function Network.sendPacket(player, identifier, packet)
	NetworkSocket:FireClient(player, identifier, packet)
end

--Function to broadcast a signal to all clients with the given packet and id
function Network.broadcastPacket(identifier, packet)
	NetworkSocket:FireAllClients(identifier, packet)
end


--Function to invoke server and wait for a response, this function yields
function Network.invokeClientAsync(player, identifier, packet, callback)
	-- invoke the server and return our packet
	local returnedPacket = RemoteFunction:InvokeClient(player, identifier, packet)
	
	-- if our return value is not nil then we call the callback
	if returnedPacket then
		-- we may want to just return a value as opposed to calling a function with the returned value
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

--Function to listen for when the server is invoked from the client
function Network.onServerInvoke(identifier, callback)
	-- cache the callback function with its respective identifier
	internal_functions[identifier] = callback
end

--Function to call any calbacks when invoked
function RemoteFunction.OnServerInvoke(player, identifier, packet)
	-- verify the exitence of the call back
	if internal_functions[identifier] then
		-- call it
		return internal_functions[identifier](player, packet, identifier)
	end
end

return Network
