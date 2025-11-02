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


--//DIALOGUE
local chatFrame = mainGui:WaitForChild("Chat")
local isOpen = false
local newDialogue

local dialogues = {
    Jerry = {
        "Hello there, traveler! Would you like to see my shop?",
        {
            ["Yes!"] = function()
                newDialogue("OpenShop")
            end,
            ["No, thanks."] = nil,
        }
    };
    OpenShop = {
        "Great! Here's what I have for sale.",
        {
            ["Buy Wood (5 Thaler)"] = function()
                events:WaitForChild("BuyItem"):InvokeServer("Wood", 5)
                newDialogue("Jerry")
            end,
            ["Buy Stone (5 Thaler)"] = function()
                events:WaitForChild("BuyItem"):InvokeServer("Stone", 5)
                newDialogue("Jerry")
            end,
            ["Leave"] = nil,
        }
    };
    broken = {
        "You broke it",
        {
            ["Sorry"] = nil,
        }
    };
}

newDialogue = function(id)

    --load text
    local goalText = dialogues[id][1] or "..."
    for i = 1, #goalText do
        chatFrame:WaitForChild("Chat").Text = string.sub(goalText, 1, i)
        task.wait(0.03)
    end

    --load options
    local picked = false
    local frames = {}
    for optionText, callback in pairs(dialogues[id][2] or {}) do
        local optionFrame = assets:WaitForChild("ChatOption"):Clone()
        optionFrame:WaitForChild("Input").Text = optionText
        optionFrame.Parent = chatFrame:WaitForChild("Options")

        frames[optionFrame] = optionFrame.MouseButton1Click:Connect(function()
            if callback then
                callback()
            end
            picked = true
        end)
    end

    --wait for pick
    repeat
        task.wait(0.1)
    until picked
end

for _, npc in pairs(workspace:WaitForChild("NPCs"):GetChildren()) do
    local prompt = npc:WaitForChild("HumanoidRootPart"):WaitForChild("TalkPrompt")
    prompt.Triggered:Connect(function(pla)
        if isOpen then return end
        isOpen = true

        chatFrame:WaitForChild("Title").Text = npc.Name:split(", ")[1] or "broken"
        chatFrame.Visible = true
        newDialogue(chatFrame.Title.Text)

        chatFrame.Visible = false
        isOpen = false
    end)
end