--// SERVICES
local Players = game:GetService("Players")
local repStorage = game:GetService("ReplicatedStorage")

--//Places
local events = repStorage:WaitForChild("Events")
local assets = repStorage:WaitForChild("Assets")
local modules = repStorage:WaitForChild("Modules")

--//MODULES
local profileStore = require(modules.ProfileStore)
local materialInfo = require(modules:WaitForChild("Materials"))
local toolInfo = require(modules.Tools)
local armorInfo = require(modules:WaitForChild("Armors"))


-- This is the default template code for profilestore
local PROFILE_TEMPLATE = {
    Materials = {
        Thaler = 20,
        Wood = 0,
        Stone = 0,
        Iron = 0,
    };
    Items = {
        {
            Name = "Wooden Pickaxe",
            Durability = 100,
        },
        {
            Name = "Wooden Axe",
            Durability = 100,
        },
    };
    Armors = {};
}


local PlayerStore = profileStore.New("PlayerStore", PROFILE_TEMPLATE)
local Profiles: {[Player]: typeof(PlayerStore:StartSessionAsync())} = require(script.profiles)


function equipBestArmor(pla)
    local profile = Profiles[pla]
    if not profile then return end

    local bestArmorName, bestArmorLayout = nil, 0
    for _, armors in pairs(profile.Data.Armors) do
        if armorInfo[armors.Name].Layout > bestArmorLayout then
            bestArmorName = armors.Name
            bestArmorLayout = armorInfo[armors.Name].Layout
        end
    end

    if not bestArmorName then return end

    --equip it

end

local function PlayerAdded(pla)

   local profile = PlayerStore:StartSessionAsync(`{pla.UserId}`, {
      Cancel = function()
         return pla.Parent ~= Players
      end,
   })
   if profile ~= nil then

      profile:AddUserId(pla.UserId)
      profile:Reconcile()

      profile.OnSessionEnd:Connect(function()
         Profiles[pla] = nil
         pla:Kick(`Profile session end - Please rejoin`)
      end)

      if pla.Parent == Players then
         Profiles[pla] = profile
         print(`Profile loaded for {pla.DisplayName}!`)
        
        --do loaded stuff
        equipBestArmor(pla)

        --give tools
        for _, toolStats in pairs(profile.Data.Items) do
            local toolClone = repStorage:WaitForChild("Tools"):WaitForChild(toolStats.Name):Clone()
            toolClone:SetAttribute("Durability", toolStats.Durability)
            toolClone.Parent = pla.Backpack
        end

      else
         profile:EndSession()
      end

   else
      pla:Kick(`Profile load fail - Please rejoin`)
   end

end

for _, pla in Players:GetPlayers() do
   task.spawn(PlayerAdded, pla)
end
Players.PlayerAdded:Connect(PlayerAdded)

Players.PlayerRemoving:Connect(function(pla)
    local profile = Profiles[pla]
    if profile == nil then return end

    local toolsToSave = {}
    for _, tool in pairs(pla.Backpack:GetChildren()) do
        table.insert(toolsToSave, {
            Name = tool.Name,
            Durability = tool:GetAttribute("Durability") or 1,
        })   
    end

    profile.Data.Items = toolsToSave

    profile:EndSession()
end)



--CRAFT ITEMS
events:WaitForChild("CraftItem").OnServerEvent:Connect(function(pla, itemName)
    local profile = Profiles[pla]
    if not profile then return end
    
    local searchTable
    if toolInfo[itemName] then
        searchTable = toolInfo[itemName]
    elseif armorInfo[itemName] then
        searchTable = armorInfo[itemName]
    else
        return -- not a real tool / armor
    end

    --check for resources
    for matName, matCost in pairs(searchTable.Cost) do
        if profile.Data.Materials[matName] < matCost then return end
    end

    --take resources
    for matName, matCost in pairs(searchTable.Cost) do
        profile.Data.Materials[matName] -= matCost
    end

    --give tool
    if toolInfo[itemName] then 
        repStorage:WaitForChild("Tools"):WaitForChild(itemName):Clone().Parent = pla.Backpack
        table.insert(profile.Data.Items, {
            Name = itemName,
            Durability = toolInfo[itemName].Durability,
        })

    --give armor  
    elseif armorInfo[itemName] then
        table.insert(profile.Data.Armors, {
            Name = itemName,
        })
        equipBestArmor(pla)
    end

    --send new materials
    events:WaitForChild("UpdateMaterials"):FireClient(pla, profile.Data.Materials)
end)