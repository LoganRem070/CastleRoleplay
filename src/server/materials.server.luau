local repStorage = game:GetService("ReplicatedStorage")

local events = repStorage:WaitForChild("Events")
local assets = repStorage:WaitForChild("Assets")
local modules = repStorage:WaitForChild("Modules")

local toolModule = require(modules:WaitForChild("Tools"))
local materialModule = require(modules.Materials)
local profiles = require(script.Parent.profiles)

function damageMatGiver(pla, object)
    if not object:GetAttribute("Health") then
        object:SetAttribute("Health", 10)
    end
    if object:GetAttribute("Health") <= 0 then return end

    local tool = pla.Character and pla.Character:FindFirstChildOfClass("Tool")
    if not tool or not tool:HasTag("Tool") then return end
    if not toolModule[tool.Name] then return end
    
    object:SetAttribute("Health", object:GetAttribute("Health") - (toolModule[tool.Name].Damage or 1))
    if not tool:GetAttribute("Durability") then
        tool:SetAttribute("Durability", toolModule[tool.Name].Durability or 1)
    end
    tool:SetAttribute("Durability", tool:GetAttribute("Durability") - 1)
    tool.ToolTip = `Durability: {tool:GetAttribute("Durability")}/{toolModule[tool.Name].Durability or 100}`
    if tool:GetAttribute("Durability") <= 0 then
        tool.Parent = nil
        game:GetService("Debris"):AddItem(tool, 5)
    end

    --give mats
    if math.random(1, (toolModule[tool.Name].Luck or 3)) == 1 and profiles[pla] then

        local matName = "Leather"
        if object.Name == "Tree" then
            matName = "Wood"
        elseif object.Name == "Rock" then
            matName = math.random(1, 3) == 1 and "Iron" or "Stone"
        end

        profiles[pla].Data.Materials[matName] += 1
        events:WaitForChild("UpdateMaterials"):FireClient(pla, profiles[pla].Data.Materials)
    end

    --deal with killing objects
    if object:GetAttribute("Health") > 0 then return end

    local function toggleTransparency(enabled)
        for _, part in pairs(object:GetChildren()) do
            if not part:IsA("BasePart") then return end
            if not part:GetAttribute("trans") then
                part:SetAttribute("trans", part.Transparency)
            end
            if not enabled then
                part.Transparency = 1
                part.CanCollide = false
            else
                part.Transparency = part:GetAttribute("trans") or 0
                part.CanCollide = true
            end
        end
    end

    toggleTransparency(false)
    task.wait(5) --COOLDOWN FOR ITEMS
    toggleTransparency(true)
    object:SetAttribute("Health", 10)

end

events:WaitForChild("ChopTree").OnServerEvent:Connect(damageMatGiver)
events:WaitForChild("MineRock").OnServerEvent:Connect(damageMatGiver)
events:WaitForChild("AttackChar").OnServerEvent:Connect(function(pla, char, tool)
    if not char:FindFirstChild("Humanoid") then return end

    char.Humanoid:TakeDamage(toolModule[tool.Name].HumanoidDamage or 0)
end)


--//MATERIALS

--other scripts update materials
events:WaitForChild("UpdateMaterial").Event:Connect(function(pla, materialName, amount)
    local profile = profiles[pla]
    if profile == nil then return end

    local materials = profile.Data.Materials
    materials[materialName] = (materials[materialName] or 0) + amount
    if materials[materialName] < 0 then
        materials[materialName] = 0
    end
    events:WaitForChild("UpdateMaterials"):FireClient(pla, materials)
end)

--GIVE PLAYER MAT STATS
events:WaitForChild("GetMaterials").OnServerInvoke = function(pla)
    local profile = profiles[pla]
    if profile ~= nil then
        return profile.Data.Materials
    else
        return {}
    end
end

--BUY AND SELL MATS
events:WaitForChild("TradeMaterial").OnServerEvent:Connect(function(pla, materialName, amt)
    local profile = profiles[pla]
    if profile == nil then return end

    if amt < 0 then -- sell
        if profile.Data.Materials[materialName] >= math.abs(amt) then
            profile.Data.Materials[materialName] += amt
            profile.Data.Materials["Thaler"] += math.abs(amt) * materialModule[materialName].SellPrice
        end
    else --buy
        if profile.Data.Materials["Thaler"] >= amt * materialModule[materialName].BuyPrice then
            profile.Data.Materials[materialName] += amt
            profile.Data.Materials["Thaler"] -= amt * materialModule[materialName].BuyPrice
        end
    end

    events:WaitForChild("UpdateMaterials"):FireClient(pla, profile.Data.Materials)
end)