 --//finite state machine by GD6_Rysing/Syharaa

--[[
	This machine data model does not support extended state capabilities
	May implement more events in the future
	
	--<USAGE>--
	local stateModule = pathToModule
	
	local my_states = {
		["Walking"] = { 
			["Stop"] = "Idle";
			["Jump"] = "Falling";
		}
		
		["Idle"] = {
			["Walk"] = "Walking;
			["Jump"] = "Falling";
		}
		
		["Falling"] = {
			["Landed"] = "Idle";
		}
	}
	
	local machine = require(stateModule).new("Idle", my_states)
	
	machine:switch("Walk")
	print(machine.current_state) --> "Walking"
	
	machine:switch("Jump")
	print(machine.current_state) --> "Falling"
	
	machine:switch("Landed")
	print(machine.current_state) --> "Idle"
	
	machine.onStateChanged:Connect(function(oldState, newState)
		print("Machine changed state from :"..oldState.." To : "..newState)
	end)
	
--]]


local machine = {}

--Dependencies
local parrelstate = require(script.Parrallel)

--Objects
local event_object = Instance.new("BindableEvent")

--Function to construct a new state machine
function machine.new(init_state, transitions)
	assert(init_state ~= nil, "first argument of constructor is nil")
	assert(transitions ~= nil, "second argument of constructor is nil")
	assert(typeof(init_state) == "string", "first argument of constructor must be a string")
	assert(typeof(transitions) == "table", "second argument of constructor must be a table")
	if not transitions[init_state] then return error("initital state must be a member of transitions table") end
	
	local self = setmetatable({}, machine)
	self.transitions = transitions
	self.current_state = init_state
	self.submachines = {}
	self.current_submachine = nil
	
	--Events
	self.StateChanged = {}
	
	-- Create event listeners
	function self.StateChanged:Connect(callback)
		local Connection = event_object.Event:Connect(function(identifier, oldState, newState)
			if identifier == "onStateChanged" then
				return callback(oldState, newState)
			end
		end)
		return Connection
	end
	
	return self
end

function machine.newParallel(transitions)
	return parrelstate.new(transitions)
end

function machine:switch(event_name, callback)
	local new_state = self:transition(event_name)
	assert(new_state, "There was an invalid transition from <"..self.current_state.."> to <"..event_name..">")
	if self.current_submachine and self.transitions[new_state] then
		self:unRegister()
	end
	
	event_object:Fire("onStateChanged", self.current_state, new_state)
	self.current_state = new_state
	if callback then
		callback()
	end
end

function machine:event(event_name, machine)
	self.submachines[event_name] = machine
end

--//used to transition to submachines and states itself
function machine:transition(event_name)
	if self.current_submachine then
		local new_state = self.current_submachine:transition(event_name)
		if new_state then return new_state end
	end

	if self.submachines[event_name] then
		self.current_submachine = self.submachines[event_name] 
		return self.current_submachine.current_state
	end
	
	return self.transitions[self.current_state][event_name]
end

function machine:unRegister()
	if self.current_submachine then
		self.current_submachine:unRegister()
		self.current_submachine = nil
	end
end


-- Apply the metamethods to the table
machine.__index = machine
return machine
