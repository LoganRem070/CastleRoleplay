local repStorage = game:GetService("ReplicatedStorage")

local pla = game:GetService("Players").LocalPlayer
local mainGui = pla:WaitForChild("PlayerGui"):WaitForChild("Main")
local char = pla.Character or pla.CharacterAdded:Wait()

local events = repStorage:WaitForChild("Events")
local assets = repStorage:WaitForChild("Assets")
local modules = repStorage:WaitForChild("Modules")

--//NOTIFACTIONS
local notifCounter = 0
function notify(text)
    local clone = assets:WaitForChild("NotifTemplate"):Clone()
    clone.Text = text
    clone.LayoutOrder = notifCounter
    notifCounter += 1
    clone.Parent = mainGui:WaitForChild("Notifs")

    local function tweeeen(val)
        local t = game:GetService("TweenService"):Create(clone,
            TweenInfo.new(1), {
            TextTransparency = val,
            TextStrokeTransparency = val,
        })
        t:Play()
        t.Completed:Wait()
    end

    tweeeen(0)
    task.delay(5, function()
        tweeeen(1)
        clone:Destroy()
    end)
end

--//MATERIALS

local materialFrame = mainGui:WaitForChild("Materials")
local materialInfo = require(modules:WaitForChild("Materials"))
function updateMaterials(materials)
    if not materials then
        materials = events:WaitForChild("GetMaterials"):InvokeServer()
    end

    for materialName :string, amount in pairs(materials) do
        
        local matLabel = materialFrame:FindFirstChild(materialName)
        if not matLabel then
            matLabel = assets:WaitForChild("MaterialTemplate"):Clone()
            matLabel.Name = materialName
            matLabel:WaitForChild("Title").Text = materialName
            matLabel:WaitForChild("Icon").Image = materialInfo[materialName].Icon
            matLabel.LayoutOrder = materialInfo[materialName].LayoutOrder
            matLabel.Parent = materialFrame
        end
        local diff = amount - tonumber(matLabel.Amount.Text)
        if diff ~= 0 then
            task.spawn(notify, `{diff > 0 and "+" or ""}{diff} {materialName:upper()}`)
        end
        matLabel.Amount.Text = amount
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
local armorInfo = require(modules:WaitForChild("Armors"))
local activeCraft = nil
function makeNewCraftable(toolName, info)
    local toolButton = assets:WaitForChild("CraftingTemplate"):Clone()
    toolButton.Name = toolName
    toolButton:WaitForChild("Title").Text = toolName
    toolButton.LayoutOrder = info.Layout
    toolButton.Parent = craftingFrame:WaitForChild("ScrollingFrame"):WaitForChild("ScrollingFrame")

    local itemClone = repStorage:WaitForChild("Tools"):FindFirstChild(toolName) or repStorage:WaitForChild("Armors"):FindFirstChild(toolName)
    if itemClone then
        itemClone = itemClone:Clone()
        itemClone:PivotTo(CFrame.new(0,0,0))
        itemClone.Parent = toolButton:WaitForChild("ViewportFrame")
    end

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
for toolName, info in pairs(toolInfo) do
    makeNewCraftable(toolName, info)
end
for armorName, info in pairs(armorInfo) do
    info.Layout += 901 --make armors appear later on
    makeNewCraftable(armorName, info)
end

--req to craft
craftingFrame:WaitForChild("Details"):WaitForChild("Button").MouseButton1Click:Connect(function()
    if not activeCraft then return end
    craftingFrame:WaitForChild("Details").Visible = false
    events:WaitForChild("CraftItem"):FireServer(activeCraft)
    activeCraft = nil
end)

--close crafting menu
craftingFrame:WaitForChild("Close").MouseButton1Click:Connect(function()
    craftingFrame.Visible = false
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
            ["I want to buy items"] = function()
                newDialogue("BuyItems")
            end,
            ["I want to sell my items"] = function()
                newDialogue("SellItems")
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
    BuyItems = {
        "Great! Here's what I have to offer.",
        {
            ["Leave"] = 0    
        }
    };
    SellItems = {
        "Great! Here's what I am looking to buy.",
        {
            ["Leave"] = 0    
        }
    };

    Timmy = {
        "Hello! Want to craft some things?",
        {
            ["Of Course!"] = function()
                craftingFrame.Visible = not craftingFrame.Visible
            end,
            ["No Thanks"] = 0,
        }
    };

    Johnny = {
        "Hello there! Want to learn more about this world?",
        {
            ["Yes!"] = function()
               newDialogue("Tut1") 
            end,
            ["No Thanks"] = 0,
        }
    };
    Tut1 = {
        "In this Medieval game you can explore the map, gather resources, and craft better items!",
        {
            ["Uh huh"] = function()
               newDialogue("Tut2") 
            end,
            ["Get lost"] = 0,
        }
    };
    Tut2 = {
        "Simply hit a tree with an axe for wood. You can also hit a rock with a pickaxe for stone and iron!",
        {
            ["Uh huh"] = function()
               newDialogue("Tut3") 
            end,
            ["Get lost"] = 0,
        }
    };
    Tut3 = {
        "You can then take these materials to the market to craft new items with Timmy.",
        {
            ["Uh huh"] = function()
               newDialogue("Tut4") 
            end,
            ["Get lost"] = 0,
        }
    };
    Tut4 = {
        "Or you could go to Jerry to sell them for Thaler, the in game currency, and then buy items from him!",
        {
            ["Uh huh"] = function()
               newDialogue("Tut5") 
            end,
            ["Get lost"] = 0,
        }
    };
    Tut5 = {
        "Buying better tools will make your resource gathering more efficent, these better tools also have more durability",
        {
            ["Uh huh"] = function()
               newDialogue("Tut6") 
            end,
            ["Get lost"] = 0,
        }
    };
    Tut6 = {
        "Have fun!",
        {
            ["Thank you!"] = 0,
            ["Lame ahh tutorial"] = 0,
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
for toolName, info in pairs(toolInfo) do
    if info.BuyPrice then
        dialogues.BuyItems[2][`Buy {toolName}\n({info.BuyPrice} Thaler)`] = function()
            events:WaitForChild("TradeItem"):FireServer(toolName, 1)
            newDialogue("BuyItems")
        end
    end
    if info.SellPrice then
        dialogues.SellItems[2][`Sell {toolName}\n({info.SellPrice} Thaler)`] = function()
            events:WaitForChild("TradeItem"):FireServer(toolName, -1)
            newDialogue("SellItems")
        end
    end
end
for armorName, info in pairs(armorInfo) do
    if info.BuyPrice then
        dialogues.BuyItems[2][`Buy {armorName}\n({info.BuyPrice} Thaler)`] = function()
            events:WaitForChild("TradeItem"):FireServer(armorName, 1)
            newDialogue("BuyItems")
        end
    end
    if info.SellPrice then
        dialogues.SellItems[2][`Sell {armorName}\n({info.SellPrice} Thaler)`] = function()
            events:WaitForChild("TradeItem"):FireServer(armorName, -1)
            newDialogue("SellItems")
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