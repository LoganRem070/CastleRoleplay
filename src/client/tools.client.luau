local pla = game:GetService("Players").LocalPlayer
local char = pla.Character or pla.CharacterAdded:Wait()

local connections = {}

char.ChildAdded:Connect(function(tool)
    if not tool:IsA("Tool") then return end
    if not game:GetService("CollectionService"):HasTag(tool, "Tool") then return end

    connections[tool] = {
        tool.Activated:Connect(function()
            print("Tool activated: " .. tool.Name)
            -- Add tool activation logic here
        end);
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