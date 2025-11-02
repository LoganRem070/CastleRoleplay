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
   if profile ~= nil then
      profile:EndSession()
   end
end)



--CRAFT ITEMS
events:WaitForChild("CraftItem").OnServerEvent:Connect(function(pla, itemName)
    local profile = Profiles[pla]
    if not profile then return end
    
    if toolInfo[itemName] then
        --check for resources
        for matName, matCost in pairs(toolInfo[itemName].Cost) do
            if profile.Data.Materials[matName] < matCost then return end
        end

        --take resources
        for matName, matCost in pairs(toolInfo[itemName].Cost) do
            profile.Data.Materials[matName] -= matCost
        end

        repStorage:WaitForChild("Tools"):WaitForChild(itemName):Clone().Parent = pla.Backpack
        table.insert(profile.Data.Items, {
            Name = itemName,
            Durability = toolInfo[itemName].Durability,
        })

        events:WaitForChild("UpdateMaterials"):FireClient(pla, profile.Data.Materials)

        return
    end
end)