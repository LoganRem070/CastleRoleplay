local repStorage = game:GetService("ReplicatedStorage")

local events = repStorage:WaitForChild("Events")
local assets = repStorage:WaitForChild("Assets")
local modules = repStorage:WaitForChild("Modules")

local pla = game:GetService("Players").LocalPlayer
local char = pla.Character or pla.CharacterAdded:Wait()
pla.CharacterAdded:Connect(function(new)
    char = new
end)

local animatorModule = require(modules:WaitForChild("Animations"))

local connections = {}

char.ChildAdded:Connect(function(tool)
    if not tool:IsA("Tool") then return end
    if not game:GetService("CollectionService"):HasTag(tool, "Tool") then return end

    local hitting = false
    local db = false
    local handle = tool:WaitForChild("Handle")
    local tooltype = ""

    if tool.Name:find(" Axe") then
        tooltype = "Axe"
    elseif tool.Name:find("Pickaxe") then
        tooltype = "Pickaxe"
    elseif tool.Name:find("Sword") then
        tooltype = "Sword"
    end

    local currentTrack = animatorModule.PlayAnimation(animatorModule.IDs[tooltype.."Idle"])

    local function checkHit(hit)
        if not hitting then return end
        if not hit or not hit.Parent then return end
        if hit == handle then return end
        if hit.Parent == handle.Parent then return end
        if hit.Parent == char then return end

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

            currentTrack:Stop()
            currentTrack = animatorModule.PlayAnimation(animatorModule.IDs[tooltype.."Swing"])

            hitting = true
            for _, v in pairs(game.Workspace:GetPartsInPart(tool:WaitForChild("Contact"))) do
                checkHit(v)
            end
            task.wait(0.7) --SWING TIME 
            hitting = false

            task.wait(0.3) --DB TIME

            if not tool or not tool.Parent then return end
            currentTrack:Stop()
            currentTrack = animatorModule.PlayAnimation(animatorModule.IDs[tooltype.."Idle"])
            db = false
        end);
        tool:WaitForChild("Contact").Touched:Connect(checkHit);
        tool:GetPropertyChangedSignal("Parent"):Connect(function()
            if tool.Parent == char then return end --still equipped

            if connections[tool] then
                for _, conn in pairs(connections[tool]) do
                    conn:Disconnect()
                end
                connections[tool] = nil
            end
            animatorModule.CancelAll()
        end)
    }

end)