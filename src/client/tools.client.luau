local repStorage = game:GetService("ReplicatedStorage")

local events = repStorage:WaitForChild("Events")
local assets = repStorage:WaitForChild("Assets")
local modules = repStorage:WaitForChild("Modules")

local pla = game:GetService("Players").LocalPlayer
local char = pla.Character or pla.CharacterAdded:Wait()

local connections = {}

char.ChildAdded:Connect(function(tool)
    if not tool:IsA("Tool") then return end
    if not game:GetService("CollectionService"):HasTag(tool, "Tool") then return end

    local hitting = false
    local db = false
    local handle = tool:WaitForChild("Handle")

    local function checkHit(hit)
        if not hitting then return end
        if not hit or not hit.Parent then return end
        
        if hit.Parent.Name == "Tree" and tool.Name:find(" Axe") then
            events:WaitForChild("ChopTree"):FireServer(hit.Parent, tool)
            hitting = false --prevent multi hits
        elseif hit.Parent.Name == "Rock" and tool.Name:find("Pickaxe") then
            events:WaitForChild("MineRock"):FireServer(hit.Parent, tool)
            hitting = false --prevent multi hits
        end

        if hit.Parent:FindFirstChild("Humanoid") then
            events:WaitForChild("AttackChar"):FireServer(hit.Parent, tool)
            hitting = false --prevent multi hits
        end

    end

    connections[tool] = {
        tool.Activated:Connect(function()
            if db then return end
            db = true
            print("Tool activated: " .. tool.Name)

            hitting = true
            for _, v in pairs(game.Workspace:GetPartsInPart(tool:WaitForChild("Contact"))) do
                if v == handle then continue end
                if v.Parent == handle.Parent then continue end
                checkHit(v)
            end
            task.wait(0.7) --SWING TIME 
            hitting = false

            task.wait(0.4) --DB TIME
            db = false
        end);
        tool:WaitForChild("Contact").Touched:Connect(checkHit);
        tool:GetPropertyChangedSignal("Parent"):Connect(function()
            if tool.Parent ~= char then
                print("Tool unequipped: " .. tool.Name)
                -- Add tool unequip logic here
                if connections[tool] then
                    for _, conn in pairs(connections[tool]) do
                        conn:Disconnect()
                    end
                    connections[tool] = nil
                end
            end
        end)
    }

end)