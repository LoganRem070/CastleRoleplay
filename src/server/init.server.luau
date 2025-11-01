--// SERVICES
local Players = game:GetService("Players")

--//MODULES
local profileStore = require(game:GetService("ReplicatedStorage").Modules.ProfileStore)




-- This is the default template code for profilestore
local PROFILE_TEMPLATE = {
   Thaler = 25;
   Items = {
        Pickaxe = 1,
        Axe = 1,
   };
   Armors = {};
}


local PlayerStore = profileStore.New("PlayerStore", PROFILE_TEMPLATE)
local Profiles: {[Player]: typeof(PlayerStore:StartSessionAsync())} = {}

local function PlayerAdded(player)

   local profile = PlayerStore:StartSessionAsync(`{player.UserId}`, {
      Cancel = function()
         return player.Parent ~= Players
      end,
   })
   if profile ~= nil then

      profile:AddUserId(player.UserId)
      profile:Reconcile()

      profile.OnSessionEnd:Connect(function()
         Profiles[player] = nil
         player:Kick(`Profile session end - Please rejoin`)
      end)

      if player.Parent == Players then
         Profiles[player] = profile
         print(`Profile loaded for {player.DisplayName}!`)
        
        --do loaded stuff

      else
         profile:EndSession()
      end

   else
      player:Kick(`Profile load fail - Please rejoin`)
   end

end

for _, player in Players:GetPlayers() do
   task.spawn(PlayerAdded, player)
end
Players.PlayerAdded:Connect(PlayerAdded)

Players.PlayerRemoving:Connect(function(player)
   local profile = Profiles[player]
   if profile ~= nil then
      profile:EndSession()
   end
end)