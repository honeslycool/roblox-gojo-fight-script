-- ServerScriptService/BasketballZeroServer.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:FindFirstChild("BasketballZero") or Instance.new("Folder")
folder.Name = "BasketballZero"
folder.Parent = ReplicatedStorage

local ballAction = ReplicatedStorage.BasketballZero:FindFirstChild("BallAction") or Instance.new("RemoteEvent")
ballAction.Name = "BallAction"
ballAction.Parent = ReplicatedStorage.BasketballZero

local ball = workspace:FindFirstChild("Basketball")
if not ball then
    ball = Instance.new("Part")
    ball.Name = "Basketball"
    ball.Shape = Enum.PartType.Ball
    ball.Size = Vector3.new(1.2, 1.2, 1.2)
    ball.Material = Enum.Material.SmoothPlastic
    ball.Color = Color3.fromRGB(255, 180, 0)
    ball.TopSurface = Enum.SurfaceType.Smooth
    ball.BottomSurface = Enum.SurfaceType.Smooth
    ball.CanCollide = true
    ball.Parent = workspace
end

local settings = {
    SpeedBoost = 25,
    DribbleHeight = 1.2,
    DribbleDistance = 2
}

local ballHolder = nil
local dribbling = false

local function getCharacter(player)
    return player.Character
end

local function getRoot(player)
    local char = getCharacter(player)
    if char then
        return char:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local function getHumanoid(player)
    local char = getCharacter(player)
    if char then
        return char:FindFirstChildOfClass("Humanoid")
    end
    return nil
end

local function setBallHeld(player)
    local root = getRoot(player)
    if not root then return end

    ballHolder = player
    ball.Anchored = true

    local weld = ball:FindFirstChild("BallWeld")
    if weld then
        weld:Destroy()
    end

    local newWeld = Instance.new("WeldConstraint")
    newWeld.Name = "BallWeld"
    newWeld.Part0 = root
    newWeld.Part1 = ball
    newWeld.Parent = root

    local offset = CFrame.new(0, 1.5, 1.8)
    ball.CFrame = root.CFrame * offset
end

local function unholdBall()
    local weld = ball:FindFirstChild("BallWeld")
    if weld then
        weld:Destroy()
    end
    ballHolder = nil
    dribbling = false
    ball.Anchored = false
end

local function startDribble(player)
    if ballHolder ~= player then
        return
    end
    dribbling = true
end

local function stopDribble(player)
    if ballHolder ~= player then
        return
    end
    dribbling = false
end

local function applySpeedBoost(player)
    local hum = getHumanoid(player)
    if not hum then
        return
    end

    local oldSpeed = hum.WalkSpeed
    hum.WalkSpeed = settings.SpeedBoost

    task.delay(3, function()
        if hum and hum.Parent then
            hum.WalkSpeed = oldSpeed
        end
    end)
end

ballAction.OnServerEvent:Connect(function(player, action, data)
    if action == "PickupBall" then
        local root = getRoot(player)
        if not root then return end

        local dist = (ball.Position - root.Position).Magnitude
        if dist <= 8 and not ballHolder then
            setBallHeld(player)
        end
        return
    end

    if action == "DropBall" then
        unholdBall()
        return
    end

    if action == "StartDribble" then
        startDribble(player)
        return
    end

    if action == "StopDribble" then
        stopDribble(player)
        return
    end

    if action == "SpeedBoost" then
        applySpeedBoost(player)
        return
    end
end)

game:GetService("RunService").Heartbeat:Connect(function()
    if ballHolder then
        local root = getRoot(ballHolder)
        if not root then
            unholdBall()
            return
        end

        if dribbling then
            -- Dribble animation: ball bounces slightly
            local offset = CFrame.new(0, settings.DribbleHeight, settings.DribbleDistance)
            ball.CFrame = root.CFrame * offset
        else
            -- Hold position
            local offset = CFrame.new(0, 1.5, 1.8)
            ball.CFrame = root.CFrame * offset
        end
    end

    if ball.Position.Y < -30 then
        ball.CFrame = CFrame.new(0, 5, 0)
        ball.AssemblyLinearVelocity = Vector3.zero
        unholdBall()
    end
end)
