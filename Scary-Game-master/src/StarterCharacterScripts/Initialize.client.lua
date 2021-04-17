local RepStore = game:GetService("ReplicatedStorage")

local Init = require(RepStore.Initialize.Character)

if not Init() then error("Failed to initialize character!") end