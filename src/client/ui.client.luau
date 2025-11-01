local repStorage = game:GetService("ReplicatedStorage")

local pla = game:GetService("Players").LocalPlayer
local mainGui = pla:WaitForChild("PlayerGui"):WaitForChild("Main")
local char = pla.Character or pla.CharacterAdded:Wait()

local events = repStorage:WaitForChild("Events")
local assets = repStorage:WaitForChild("Assets")
local modules = repStorage:WaitForChild("Modules")

--//MATERIALS

local materialFrame = mainGui:WaitForChild("Materials")
local materialInfo = require(modules:WaitForChild("Materials"))
function updateMaterials(materials)
    if not materials then
        materials = events:WaitForChild("GetMaterials"):InvokeServer()
    end

    for materialName, amount in pairs(materials) do
        
        local matLabel = materialFrame:FindFirstChild(materialName)
        if not matLabel then
            matLabel = assets:WaitForChild("MaterialTemplate"):Clone()
            matLabel.Name = materialName
            matLabel:WaitForChild("Title").Text = materialName
            matLabel:WaitForChild("Icon").Image = materialInfo[materialName].Icon
            matLabel.LayoutOrder = materialInfo[materialName].LayoutOrder
            matLabel.Parent = materialFrame
        end
        matLabel:WaitForChild("Amount").Text = amount
        matLabel.Visible = amount > 0 --only visible if u have some

    end
end
updateMaterials(nil)
events:WaitForChild("UpdateMaterials").OnClientEvent:Connect(function(materials)
    updateMaterials(materials)
end)