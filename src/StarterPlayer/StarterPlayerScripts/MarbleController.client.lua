--[=[
MarbleController.client.lua

LocalScript that lives in StarterPlayer > StarterPlayerScripts. It reads input
from the player's keyboard/gamepad, applies force to the marble using
VectorForce/AngularVelocity, follows up with a trailing third-person camera,
and handles jump/respawn requests.
]=]

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local config = require(ReplicatedStorage:WaitForChild("MarbleConfig"))
local remotes = ReplicatedStorage:WaitForChild("MarbleRemotes")

local player = Players.LocalPlayer

local movement = Vector3.new()
local jumpRequested = false
local cameraOffset = Vector3.new(0, 35, 65)

local marblesFolder
local currentMarble
local currentForce
local currentAngular

local activeDirections = {}
local renderConnection

local MOVE_DIRECTIONS = {
    [Enum.KeyCode.W] = Vector3.new(0, 0, -1),
    [Enum.KeyCode.S] = Vector3.new(0, 0, 1),
    [Enum.KeyCode.A] = Vector3.new(-1, 0, 0),
    [Enum.KeyCode.D] = Vector3.new(1, 0, 0),
    [Enum.KeyCode.Up] = Vector3.new(0, 0, -1),
    [Enum.KeyCode.Down] = Vector3.new(0, 0, 1),
    [Enum.KeyCode.Left] = Vector3.new(-1, 0, 0),
    [Enum.KeyCode.Right] = Vector3.new(1, 0, 0),
}

local function refreshMovement()
    local vector = Vector3.new()
    for _, dir in pairs(activeDirections) do
        vector += dir
    end

    if vector.Magnitude > 1 then
        vector = vector.Unit
    end

    movement = vector
end

local function clearActiveDirections()
    for key in pairs(activeDirections) do
        activeDirections[key] = nil
    end
    movement = Vector3.new()
end

-- Input ----------------------------------------------------------------------

local function onMove(actionName, inputState, inputObject)
    if inputObject.KeyCode == Enum.KeyCode.Thumbstick1 then
        if inputState == Enum.UserInputState.End then
            activeDirections[inputObject.KeyCode] = nil
        else
            local gamepadDirection = Vector3.new(inputObject.Position.X, 0, -inputObject.Position.Y)
            if gamepadDirection.Magnitude < 0.1 then
                activeDirections[inputObject.KeyCode] = nil
            else
                activeDirections[inputObject.KeyCode] = gamepadDirection
            end
        end

        refreshMovement()
        return Enum.ContextActionResult.Sink
    end

    local mapped = MOVE_DIRECTIONS[inputObject.KeyCode]
    if not mapped then
        return Enum.ContextActionResult.Pass
    end

    if inputState == Enum.UserInputState.Begin then
        activeDirections[inputObject.KeyCode] = mapped
    elseif inputState == Enum.UserInputState.End then
        activeDirections[inputObject.KeyCode] = nil
    end

    refreshMovement()
    return Enum.ContextActionResult.Sink
end

local function onJump(actionName, inputState)
    if inputState == Enum.UserInputState.Begin then
        jumpRequested = true
    end
    return Enum.ContextActionResult.Sink
end

-- Camera ---------------------------------------------------------------------

local function updateCamera(dt)
    if not currentMarble then
        return
    end

    local camera = workspace.CurrentCamera
    local targetCFrame = currentMarble.CFrame * CFrame.new(cameraOffset)

    camera.CameraType = Enum.CameraType.Scriptable
    camera.CFrame = camera.CFrame:Lerp(targetCFrame, math.clamp(dt * 5, 0, 1))
end

-- Marble control -------------------------------------------------------------

local function getMarblesFolder()
    if not marblesFolder then
        marblesFolder = workspace:FindFirstChild("PlayerMarbles")
        if not marblesFolder then
            marblesFolder = workspace:WaitForChild("PlayerMarbles", 5)
        end
    end

    return marblesFolder
end

local function findMarble()
    local folder = getMarblesFolder()
    if not folder then
        return
    end
    return folder:FindFirstChild(player.Name) or folder:WaitForChild(player.Name, 5)
end

local function populateAttachments(marble)
    currentForce = marble:FindFirstChild("ControlForce")
    currentAngular = marble:FindFirstChild("Spin")

    if currentForce and currentForce:IsA("VectorForce") then
        currentForce.RelativeTo = Enum.ActuatorRelativeTo.World
    end
end

local function stepControl(dt)
    if not currentMarble or not currentForce or not currentAngular then
        return
    end

    local camera = workspace.CurrentCamera
    local forward = camera.CFrame.LookVector
    local right = camera.CFrame.RightVector

    local moveDirection = (forward * -movement.Z + right * movement.X)
    local moveMagnitude = math.clamp(movement.Magnitude, 0, 1)
    if moveDirection.Magnitude > 0 then
        moveDirection = moveDirection.Unit * moveMagnitude
    else
        moveDirection = Vector3.new()
    end

    local desiredVelocity = moveDirection * config.Marble.MaxSpeed
    local currentVelocity = currentMarble.AssemblyLinearVelocity
    local delta = desiredVelocity - currentVelocity

    local force = delta * config.Marble.ForceScale
    force = Vector3.new(force.X, 0, force.Z)
    currentForce.Force = force

    if movement.Magnitude > 0 then
        local angular = Vector3.new(moveDirection.Z, 0, -moveDirection.X) * config.Marble.MaxSpeed
        currentAngular.AngularVelocity = angular
    else
        currentAngular.AngularVelocity = currentAngular.AngularVelocity:Lerp(Vector3.new(), math.clamp(dt * 5, 0, 1))
    end

    if jumpRequested then
        jumpRequested = false
        local upward = Vector3.new(0, config.Marble.JumpImpulse, 0)
        currentMarble:ApplyImpulse(upward * currentMarble.AssemblyMass)
    end
end

-- Respawn --------------------------------------------------------------------

local function onInputBegan(input, processed)
    if processed then
        return
    end

    if input.KeyCode == Enum.KeyCode.R then
        remotes.RequestRespawn:InvokeServer()
    end
end

-- Connections ----------------------------------------------------------------

local function setup()
    currentMarble = findMarble()
    if not currentMarble then
        warn("Marble not found for player", player.Name)
        return
    end

    populateAttachments(currentMarble)
    clearActiveDirections()

    ContextActionService:UnbindAction("MarbleMove")
    ContextActionService:UnbindAction("MarbleJump")

    ContextActionService:BindAction(
        "MarbleMove",
        onMove,
        false,
        Enum.KeyCode.W,
        Enum.KeyCode.A,
        Enum.KeyCode.S,
        Enum.KeyCode.D,
        Enum.KeyCode.Up,
        Enum.KeyCode.Down,
        Enum.KeyCode.Left,
        Enum.KeyCode.Right,
        Enum.KeyCode.Thumbstick1
    )

    ContextActionService:BindAction("MarbleJump", onJump, false, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)

    if renderConnection then
        renderConnection:Disconnect()
    end

    renderConnection = RunService.RenderStepped:Connect(function(dt)
        stepControl(dt)
        updateCamera(dt)
    end)
end

player.CharacterAdded:Connect(function()
    task.wait(1)
    setup()
end)

if player.Character then
    task.spawn(function()
        task.wait(1)
        setup()
    end)
end

local folder = getMarblesFolder()
if folder then
    folder.ChildAdded:Connect(function(child)
        if child.Name == player.Name then
            task.delay(0.2, setup)
        end
    end)
else
    task.spawn(function()
        local created = getMarblesFolder()
        if created then
            created.ChildAdded:Connect(function(child)
                if child.Name == player.Name then
                    task.delay(0.2, setup)
                end
            end)
        end
    end)
end

UserInputService.InputBegan:Connect(onInputBegan)
