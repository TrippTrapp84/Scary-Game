local RepStore = game:GetService("ReplicatedStorage")

local Init = require(RepStore.Initialize.Client)

if not Init() then error("Failed to initialize client!") end