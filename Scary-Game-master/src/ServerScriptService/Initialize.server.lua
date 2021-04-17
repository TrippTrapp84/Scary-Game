local RepStore = game:GetService("ReplicatedStorage")

local Init = require(RepStore.Initialize.Server)

if not Init() then error("Failed to initialize server!") end