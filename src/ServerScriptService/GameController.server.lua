--[=[
    GameController.server.lua

    Drop this Script inside ServerScriptService. It wires the core rules for a
    cooperative marble rolling game: player marbles are generated on spawn, coins
    and checkpoints are managed on the server, and round timing/leaderboards are
    kept authoritative. The script procedurally builds a simple obby-like course
    based on the configuration module so you can play immediately.
]=]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local config = require(ReplicatedStorage:WaitForChild("MarbleConfig"))

local REMOTE_FOLDER_NAME = "MarbleRemotes"
local MARBLE_FOLDER_NAME = "PlayerMarbles"

local remotesFolder
local marbleFolder
local coinsFolder
local checkpointsFolder

local playerState = {}
local leaderboard
local statusValue

local bindCoin
local bindCheckpoint
local updateLeaderboard

-- Utility --------------------------------------------------------------------

local function getOrCreate(parent, className, name)
    local child = parent:FindFirstChild(name)
    if child and child:IsA(className) then
        return child
    end

    child = Instance.new(className)
    child.Name = name
    child.Parent = parent
    return child
end

local function ensureRemoteEvents()
    remotesFolder = getOrCreate(ReplicatedStorage, "Folder", REMOTE_FOLDER_NAME)

    getOrCreate(remotesFolder, "RemoteEvent", "TimerBroadcast")
    getOrCreate(remotesFolder, "RemoteEvent", "CoinCollected")
    getOrCreate(remotesFolder, "RemoteFunction", "RequestRespawn")
end

local function ensureContainers()
    marbleFolder = getOrCreate(workspace, "Folder", MARBLE_FOLDER_NAME)
    coinsFolder = getOrCreate(workspace, "Folder", "CourseCoins")
    checkpointsFolder = getOrCreate(workspace, "Folder", "CourseCheckpoints")
    leaderboard = getOrCreate(ServerStorage, "Folder", "MarbleLeaderboard")
    statusValue = getOrCreate(ReplicatedStorage, "StringValue", "MarbleStatus")
end

local function clearFolder(folder)
    for _, child in ipairs(folder:GetChildren()) do
        child:Destroy()
    end
end

local function createForceAttachments(marble)
    local attachment = Instance.new("Attachment")
    attachment.Name = "ForceAttachment"
    attachment.Parent = marble

    local vectorForce = Instance.new("VectorForce")
    vectorForce.Attachment0 = attachment
    vectorForce.Name = "ControlForce"
    vectorForce.Force = Vector3.new()
    vectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
    vectorForce.Parent = marble

    local angularVelocity = Instance.new("AngularVelocity")
    angularVelocity.Attachment0 = attachment
    angularVelocity.Name = "Spin"
    angularVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
    angularVelocity.AngularVelocity = Vector3.new()
    angularVelocity.MaxTorque = math.huge
    angularVelocity.Parent = marble

    return vectorForce, angularVelocity
end

local function applyLighting()
    Lighting.Ambient = config.Lighting.Ambient
    Lighting.OutdoorAmbient = config.Lighting.OutdoorAmbient
    Lighting.Brightness = config.Lighting.Brightness
end

-- Course building -------------------------------------------------------------

local function createFloor()
    local base = Instance.new("Part")
    base.Name = "CourseFloor"
    base.Anchored = true
    base.Size = Vector3.new(650, 2, 180)
    base.CFrame = CFrame.new(300, 0, 0)
    base.Material = Enum.Material.Concrete
    base.Color = Color3.fromRGB(120, 120, 120)
    base.TopSurface = Enum.SurfaceType.Smooth
    base.BottomSurface = Enum.SurfaceType.Smooth
    base.Parent = workspace

    local sides = Instance.new("Folder")
    sides.Name = "SideWalls"
    sides.Parent = base

    for i = 1, 2 do
        local wall = Instance.new("Part")
        wall.Anchored = true
        wall.Size = Vector3.new(650, 25, 2)
        wall.CFrame = base.CFrame * CFrame.new(0, 12, (i == 1) and -91 or 91)
        wall.Material = Enum.Material.Plastic
        wall.Color = Color3.fromRGB(38, 38, 38)
        wall.Parent = sides
    end

    local finishPlate = Instance.new("Part")
    finishPlate.Name = "FinishPlate"
    finishPlate.Size = Vector3.new(26, 1, 26)
    finishPlate.Anchored = true
    finishPlate.Material = Enum.Material.Neon
    finishPlate.Color = Color3.fromRGB(60, 255, 214)
    finishPlate.CFrame = CFrame.new(config.Course.Checkpoints[#config.Course.Checkpoints].Position)
    finishPlate.CFrame += Vector3.new(0, -config.Course.Checkpoints[#config.Course.Checkpoints].Radius, 0)
    finishPlate.Parent = base

    return base
end

local function createRamp(position, size, rotation)
    local ramp = Instance.new("Part")
    ramp.Name = "Ramp"
    ramp.Anchored = true
    ramp.Material = Enum.Material.Metal
    ramp.Color = Color3.fromRGB(245, 208, 66)
    ramp.Size = size
    ramp.CFrame = CFrame.new(position) * CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))
    ramp.TopSurface = Enum.SurfaceType.Smooth
    ramp.BottomSurface = Enum.SurfaceType.Smooth
    ramp.Parent = workspace
    return ramp
end

local function createCourse()
    clearFolder(coinsFolder)
    clearFolder(checkpointsFolder)

    createFloor()

    createRamp(Vector3.new(90, 10, 0), Vector3.new(50, 4, 30), Vector3.new(0, 0, -15))
    createRamp(Vector3.new(200, 25, -40), Vector3.new(60, 4, 28), Vector3.new(18, 25, 0))
    createRamp(Vector3.new(320, 40, 35), Vector3.new(50, 4, 26), Vector3.new(-10, -18, 0))
    createRamp(Vector3.new(460, 55, -25), Vector3.new(65, 4, 30), Vector3.new(12, 12, 0))

    for index, checkpoint in ipairs(config.Course.Checkpoints) do
        local part = Instance.new("Part")
        part.Name = checkpoint.Name
        part.Shape = Enum.PartType.Ball
        part.Material = Enum.Material.Neon
        part.Color = checkpoint.IsFinish and Color3.fromRGB(85, 255, 127) or Color3.fromRGB(60, 165, 255)
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = 0.35
        part.Size = Vector3.new(checkpoint.Radius * 2, checkpoint.Radius * 2, checkpoint.Radius * 2)
        part.CFrame = CFrame.new(checkpoint.Position)
        part:SetAttribute("Index", index)
        part:SetAttribute("IsFinish", checkpoint.IsFinish or false)
        part.Parent = checkpointsFolder
    end

    math.randomseed(os.time())
    for i = 1, config.Course.CoinCount do
        local coin = Instance.new("Part")
        coin.Name = "Coin" .. i
        coin.Shape = Enum.PartType.Cylinder
        coin.Material = Enum.Material.Neon
        coin.Color = Color3.fromRGB(255, 229, 92)
        coin.Size = Vector3.new(5, 0.6, 5)
        coin.Orientation = Vector3.new(0, 0, 90)
        coin.Anchored = true

        local offset = Vector3.new(
            math.random() * config.Course.CoinSpread.X,
            math.random() * config.Course.CoinSpread.Y,
            (math.random() - 0.5) * config.Course.CoinSpread.Z
        )
        coin.CFrame = CFrame.new(config.Course.SpawnPosition + offset)
        coin.Parent = coinsFolder

        local spin = TweenService:Create(
            coin,
            TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true),
            {Orientation = coin.Orientation + Vector3.new(0, 360, 0)}
        )
        spin:Play()
    end
end

-- Player management ----------------------------------------------------------

local function makeMarbleColor(player)
    local defaultMaterial = config:GetDefaultMaterial()

    local hue = (player.UserId % 360) / 360
    local color = Color3.fromHSV(hue, 0.6, 1)
    defaultMaterial.Color = color
    defaultMaterial.TrailColor = color:Lerp(Color3.fromRGB(255, 255, 255), 0.25)

    return defaultMaterial
end

local function createMarbleForPlayer(player)
    local marble = Instance.new("Part")
    marble.Name = player.Name
    marble.Shape = Enum.PartType.Ball
    marble.Material = Enum.Material.SmoothPlastic
    marble.Size = Vector3.new(config.Marble.Radius * 2, config.Marble.Radius * 2, config.Marble.Radius * 2)
    marble.CustomPhysicalProperties = PhysicalProperties.new(
        config.Marble.Density,
        config.Marble.Friction,
        0.5,
        config.Marble.Elasticity,
        config.Marble.FrictionWeight
    )

    local material = makeMarbleColor(player)
    marble.Color = material.Color
    marble.Position = config.Course.SpawnPosition
    marble.CanCollide = true
    marble.CastShadow = true
    marble.Parent = marbleFolder

    local bodyForce, angularVelocity = createForceAttachments(marble)

    local trail = Instance.new("Trail")
    trail.Name = "Trail"
    trail.Color = ColorSequence.new(material.TrailColor)
    trail.FaceCamera = true
    trail.Lifetime = 0.35
    trail.WidthScale = NumberSequence.new(1, 0)

    local attach0 = Instance.new("Attachment")
    attach0.Parent = marble
    attach0.Name = "TrailAttachment0"

    local attach1 = Instance.new("Attachment")
    attach1.Parent = marble
    attach1.Name = "TrailAttachment1"
    attach1.Position = Vector3.new(0, -config.Marble.Radius, 0)

    trail.Attachment0 = attach0
    trail.Attachment1 = attach1
    trail.Parent = marble

    playerState[player] = {
        Marble = marble,
        Force = bodyForce,
        Angular = angularVelocity,
        Coins = 0,
        LastCoins = 0,
        StartTime = os.clock(),
        CheckpointIndex = 0,
        BestTime = math.huge,
        FinishedRuns = 0,
    }

    return marble
end

local function resolvePlayerFromHit(hit)
    if not hit then
        return nil
    end

    local player = Players:GetPlayerFromCharacter(hit.Parent)
    if player then
        return player
    end

    for candidate, state in pairs(playerState) do
        if state.Marble == hit then
            return candidate
        end
    end

    return nil
end

function bindCoin(coin)
    local collected = false
    coin.Touched:Connect(function(hit)
        if collected then
            return
        end

        local player = resolvePlayerFromHit(hit)
        if player and playerState[player] then
            collected = true
            coin.Transparency = 1
            coin.CanCollide = false
            coin.Anchored = false
            coin.Velocity = Vector3.new(0, 18, 0)
            coin:Destroy()

            local state = playerState[player]
            state.Coins += 1
            remotesFolder.CoinCollected:FireClient(player, state.Coins)
        end
    end)
end

function bindCheckpoint(checkpoint, index)
    checkpoint.Touched:Connect(function(hit)
        local player = resolvePlayerFromHit(hit)
        if not player then
            return
        end

        local state = playerState[player]
        if not state then
            return
        end

        if state.CheckpointIndex >= index then
            return
        end

        state.CheckpointIndex = index
        remotesFolder.TimerBroadcast:FireClient(player, "Checkpoint", index, state.Coins)

        if checkpoint:GetAttribute("IsFinish") then
            local elapsed = os.clock() - state.StartTime
            state.BestTime = math.min(state.BestTime, elapsed)
            state.FinishedRuns += 1
            state.LastCoins = state.Coins
            statusValue.Value = string.format("%s finished in %.2f seconds!", player.DisplayName, elapsed)
            updateLeaderboard()
            task.delay(3, function()
                if playerState[player] == state then
                    resetPlayer(player)
                end
            end)
        else
            statusValue.Value = string.format("%s reached checkpoint %d", player.DisplayName, index)
        end
    end)
end

local function resetPlayer(player)
    local state = playerState[player]
    if not state then
        return
    end

    state.StartTime = os.clock()
    state.CheckpointIndex = 0
    state.Coins = 0

    local marble = state.Marble
    if marble then
        marble.AssemblyLinearVelocity = Vector3.new()
        marble.AssemblyAngularVelocity = Vector3.new()
        marble.CFrame = CFrame.new(config.Course.SpawnPosition)
    end

    remotesFolder.TimerBroadcast:FireClient(player, "Reset", 0, 0)
end

function updateLeaderboard()
    clearFolder(leaderboard)

    local sorted = {}
    for player, state in pairs(playerState) do
        if state.FinishedRuns > 0 then
            table.insert(sorted, {
                Player = player,
                BestTime = state.BestTime,
                Runs = state.FinishedRuns,
                Coins = state.LastCoins or state.Coins,
            })
        end
    end

    table.sort(sorted, function(a, b)
        return a.BestTime < b.BestTime
    end)

    for rank, data in ipairs(sorted) do
        local value = Instance.new("StringValue")
        value.Name = string.format("%02d_%s", rank, data.Player.Name)
        value.Value = string.format("%s - %.2fs (%d coins)", data.Player.DisplayName, data.BestTime, data.Coins)
        value.Parent = leaderboard
    end
end

local function removePlayer(player)
    local state = playerState[player]
    if not state then
        return
    end

    if state.Marble then
        state.Marble:Destroy()
    end

    playerState[player] = nil
    updateLeaderboard()
end

-- Connections ----------------------------------------------------------------

local function onRequestRespawn(player)
    resetPlayer(player)
    return true
end

local function onPlayerAdded(player)
    player.CharacterAutoLoads = false

    player.AncestryChanged:Connect(function()
        if not player.Parent then
            removePlayer(player)
        end
    end)

    createMarbleForPlayer(player)
    resetPlayer(player)

    player.CharacterAdded:Connect(function(character)
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = true
        end
    end)

    player:LoadCharacter()

    statusValue.Value = string.format("%s joined the course!", player.DisplayName)
end

local function init()
    ensureRemoteEvents()
    ensureContainers()
    applyLighting()
    createCourse()

    for _, coin in ipairs(coinsFolder:GetChildren()) do
        bindCoin(coin)
    end

    local checkpointParts = checkpointsFolder:GetChildren()
    table.sort(checkpointParts, function(a, b)
        return (a:GetAttribute("Index") or 0) < (b:GetAttribute("Index") or 0)
    end)

    for _, checkpoint in ipairs(checkpointParts) do
        bindCheckpoint(checkpoint, checkpoint:GetAttribute("Index") or 0)
    end

    remotesFolder.RequestRespawn.OnServerInvoke = onRequestRespawn
    Players.PlayerAdded:Connect(onPlayerAdded)
    Players.PlayerRemoving:Connect(removePlayer)

    statusValue.Value = "Roll to the finish!"

    RunService.Heartbeat:Connect(function()
        for player, state in pairs(playerState) do
            if state and state.Marble and state.StartTime then
                local elapsed = os.clock() - state.StartTime
                remotesFolder.TimerBroadcast:FireClient(player, "Tick", elapsed, state.Coins)
            end
        end
    end)
end

init()
