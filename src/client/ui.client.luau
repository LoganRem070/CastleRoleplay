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


--//CRAFTING

local craftingFrame = mainGui:WaitForChild("Crafting")
local toolInfo = require(modules:WaitForChild("Tools"))
local activeCraft = nil
for toolName, info in pairs(toolInfo) do
    local toolButton = assets:WaitForChild("CraftingTemplate"):Clone()
    toolButton.Name = toolName
    toolButton:WaitForChild("Title").Text = toolName
    toolButton.LayoutOrder = info.Layout
    toolButton.Parent = craftingFrame:WaitForChild("ScrollingFrame"):WaitForChild("ScrollingFrame")

    toolButton.MouseButton1Click:Connect(function()
        
        --clear old elements
        for _, child in pairs(craftingFrame:WaitForChild("Details"):waitForChild("Elements"):GetChildren()) do
            if not child:IsA("TextLabel") then continue end
            if child.Name == "Title" then continue end
            child:Destroy()
        end

        --set new stuff
        activeCraft = toolName
        craftingFrame:WaitForChild("Details"):WaitForChild("Title").Text = toolName

        --make new elements
        for matName, reqAmount in pairs(info.Cost) do
            local matLabel = craftingFrame:WaitForChild("Details"):WaitForChild("Elements"):WaitForChild("Title"):Clone()
            matLabel.Name = matName
            matLabel.Text = `x{reqAmount} - {matName}`
            matLabel.Parent = craftingFrame:WaitForChild("Details"):WaitForChild("Elements")
        end

        craftingFrame:WaitForChild("Details").Visible = true

    end)
end

--req to craft
craftingFrame:WaitForChild("Details"):WaitForChild("Button").MouseButton1Click:Connect(function()
    if not activeCraft then return end
    craftingFrame:WaitForChild("Details").Visible = false
    events:WaitForChild("CraftItem"):FireServer(activeCraft)
    activeCraft = nil
end)


--//DIALOGUE
local chatFrame = mainGui:WaitForChild("Chat")
local isOpen = false
local newDialogue

local dialogues = {
    Jerry = {
        "Hello there, traveler! Would you like to see my shop?",
        {
            ["I want to buy materials"] = function()
                newDialogue("BuyMaterials")
            end,
            ["I want to sell materials"] = function()
                newDialogue("SellMaterials")
            end,
            ["No, thanks."] = 0,
        }
    };
    BuyMaterials = {
        "Great! Here's what I have for sale.",
        {
            ["Leave"] = 0    
        }
    };
    SellMaterials = {
        "Great! Here's what I am looking to buy.",
        {
            ["Leave"] = 0    
        }
    };
    broken = {
        "You broke it",
        {
            ["Sorry"] = 0,
        }
    };
}

--special openshop one with stuff
for matName, info in pairs(materialInfo) do
    if info.BuyPrice then
        dialogues.BuyMaterials[2][`Buy {matName}\n({info.BuyPrice} Thaler)`] = function()
            events:WaitForChild("TradeMaterial"):FireServer(matName, 1)
            newDialogue("BuyMaterials")
        end
    end
    if info.SellPrice then
        dialogues.SellMaterials[2][`Sell {matName}\n({info.SellPrice} Thaler)`] = function()
            events:WaitForChild("TradeMaterial"):FireServer(matName, -1)
            newDialogue("SellMaterials")
        end
    end
end

newDialogue = function(id)

    --load text
    local goalText = dialogues[id][1] or "..."
    for i = 1, #goalText do
        chatFrame:WaitForChild("Chat").Text = string.sub(goalText, 1, i)
        task.wait(0.03)
    end

    --load options
    local picked = nil
    local frames = {}
    for optionText, callback in pairs(dialogues[id][2] or {}) do
        local optionFrame = assets:WaitForChild("ChatOption"):Clone()
        optionFrame:WaitForChild("Input").Text = optionText
        optionFrame.Parent = chatFrame:WaitForChild("Options")

        frames[optionFrame] = optionFrame.MouseButton1Click:Connect(function()
            picked = callback
        end)
        if callback == 0 then
            optionFrame.LayoutOrder = 99999
        end
    end

    --wait for pick
    repeat
        task.wait(0.1)
    until picked

    --clear options
    for frame, conn in pairs(frames) do
        conn:Disconnect()
        frame:Destroy()
    end

    --run new dialogue if given
    if picked and picked ~= 0 then
        picked()
    end
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