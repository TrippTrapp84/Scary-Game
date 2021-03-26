--[[
	--<USAGE>--
 	The parralel state creates a new machine or a sub-machine per state

	local stateModule = pathToModule
	
	local states_parrallel = {
		["Eating"] = state_module.new("False",{
			["False"] = {["Active"] = "True"};
			["True"] = {["Inactive"] = "False"}
		});
		["Jumping"] = state_module.new("False",{
			["False"] = {["Active"] = "True"};
			["True"] = {["Inactive"] = "False"}
		});
	}
	local machine = require(stateModule).newParrallel(states_parrallel)
	
	machine:switch("Eating:Active")
	machine:switch("Jumping:Active")
	
	Now both the Eating and Jumping states are active, indicating that these are the machine's current active states
--]]

local state = {}
state.__index = state

function state.new(transitions)
	assert(typeof(transitions) == "table", "argument of constructor must be a table")
	local self = setmetatable({}, state)
	
	self.transitions = transitions
	self.scopes = {} 
	table.foreach(transitions, function(i,v) table.insert(self.scopes, i, tostring(i))  end)
	self.states = setmetatable({}, {
		__call = function()
			for i,v in pairs(self.scopes) do
				self.states[v] = self.transitions[v].self.states
				return self.states
			end
			return 
		end
		})
	return self
end

function state:switch(event_name)
	assert(string.find(event_name, ":"), "There was an invaid transition from <"..self.states[1].."> to <"..event_name.."> for parrallel state")
	local name_split = string.split(event_name, ":")
	local scope = name_split[1]
	local event = name_split[2]
	
	assert(scope, "Invalid scope: "..scope.." for parrallel switching")
	self.transitions[scope]:switch(event)
end

return state
