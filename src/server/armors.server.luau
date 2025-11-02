local repStorage = game:GetService("ReplicatedStorage")

local events = repStorage:WaitForChild("Events")
local assets = repStorage:WaitForChild("Assets")
local modules = repStorage:WaitForChild("Modules")

local toolModule = require(modules:WaitForChild("Tools"))
local materialModule = require(modules.Materials)
local profiles = require(script.Parent.profiles)


