for _, npc in pairs(workspace:WaitForChild("NPCs"):GetChildren()) do
    local humanoid = npc:WaitForChild("Humanoid")

    --settings
    humanoid.MaxHealth = math.huge
    humanoid.Health = math.huge
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

    --overheads
    local nameSplit = npc.Name:split(", ")
    local overhead = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Overhead"):Clone()
    overhead:WaitForChild("Extra").Text = "NPC"
    overhead:WaitForChild("Username").Text = nameSplit[1] or "broken"
    overhead:WaitForChild("Duchy").Text = "Holy Roman Empire"
    overhead:WaitForChild("Rank").Text = nameSplit[2] or "broken"
    overhead.Adornee = npc:WaitForChild("Head")
    overhead.Parent = npc

    --proximity prompt
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Talk"
    prompt.ObjectText = nameSplit[1] or "broken"
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = 10
    prompt.Name = "TalkPrompt"
    prompt.RequiresLineOfSight = false
    prompt.Parent = npc:WaitForChild("HumanoidRootPart")

end