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


-- This is the default template code for profilestore
local PROFILE_TEMPLATE = {
    Materials = {
        Thaler = 20,
        Wood = 0,
        Stone = 0,
        Iron = 0,
    };
    Items = {
        Pickaxe = 1,
        Axe = 1,
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


--//MATERIALS

function updateMaterial(pla, materialName, amount)
    local profile = Profiles[pla]
    if profile == nil then return end

    local materials = profile.Data.Materials
    materials[materialName] = (materials[materialName] or 0) + amount
    if materials[materialName] < 0 then
        materials[materialName] = 0
    end
    events:WaitForChild("UpdateMaterials"):FireClient(pla, materials)
end
events:WaitForChild("UpdateMaterial").Event:Connect(updateMaterial)

events:WaitForChild("GetMaterials").OnServerInvoke = function(pla)
    local profile = Profiles[pla]
    if profile ~= nil then
        return profile.Data.Materials
    else
        return {}
    end
end

events:WaitForChild("TradeMaterial").OnServerEvent:Connect(function(pla, materialName, amt)
    local profile = Profiles[pla]
    if profile == nil then return end

    if amt < 0 then -- sell
        if profile.Data.Materials[materialName] >= math.abs(amt) then
            profile.Data.Materials[materialName] += amt
            profile.Data.Materials["Thaler"] += math.abs(amt) * materialInfo[materialName].SellPrice
        end
    else --buy
        if profile.Data.Materials["Thaler"] >= amt * materialInfo[materialName].BuyPrice then
            profile.Data.Materials[materialName] += amt
            profile.Data.Materials["Thaler"] -= amt * materialInfo[materialName].BuyPrice
        end
    end

    events:WaitForChild("UpdateMaterials"):FireClient(pla, profile.Data.Materials)
end)