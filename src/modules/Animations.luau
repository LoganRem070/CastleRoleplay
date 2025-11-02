local module = {}

module.IDs = {
    AxeIdle = 71908953605356,
    AxeSwing = 80596860185546,
    PickaxeIdle = 122159244208589,
    PickaxeSwing = 112054702883933,

    --i dont wanna make more, sword is using axe anims, cry about it
    SwordIdle = 71908953605356,
    SwordSwing = 80596860185546,
}

function getStuff()
    if game:GetService("RunService"):IsServer() then
        return nil
    end
    local pla = game:GetService("Players").LocalPlayer
    local char = pla.Character or pla.CharacterAdded:Wait()
    local humanoid = char:WaitForChild("Humanoid")
    local animator = humanoid:WaitForChild("Animator")
    return pla, char, humanoid, animator
end

module.CancelAll = function()
    local pla, char, humanoid, animator = getStuff()
    if not pla or not char or not humanoid or not animator then return end

    for _, track :AnimationTrack in pairs(animator:GetPlayingAnimationTracks()) do
        if track.Priority ~= Enum.AnimationPriority.Action then continue end
        track:Stop()
    end
end

module.PlayAnimation = function(animID)
    local pla, char, humanoid, animator = getStuff()
    if not pla or not char or not humanoid or not animator then return end

    local animation = Instance.new("Animation")
    animation.AnimationId = `rbxassetid://{animID}`

    local track = animator:LoadAnimation(animation)
    track:Play()
    return track
end

return module