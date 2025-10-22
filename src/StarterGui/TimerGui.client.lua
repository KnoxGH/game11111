--[=[
TimerGui.client.lua

LocalScript for StarterGui. Builds a minimalist HUD containing the current run
time, coin total, and status messages broadcast from the server.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local config = require(ReplicatedStorage:WaitForChild("MarbleConfig"))
local remotes = ReplicatedStorage:WaitForChild("MarbleRemotes")
local statusValue = ReplicatedStorage:WaitForChild("MarbleStatus")

local player = Players.LocalPlayer

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MarbleHud"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimerLabel"
timerLabel.Size = UDim2.new(0, 260, 0, 64)
timerLabel.Position = UDim2.fromScale(0.5, 0.06)
timerLabel.AnchorPoint = Vector2.new(0.5, 0)
timerLabel.TextScaled = true
timerLabel.Font = config.Interface.Font
timerLabel.TextColor3 = config.Interface.TextColor
timerLabel.TextStrokeColor3 = config.Interface.StrokeColor
timerLabel.TextStrokeTransparency = 0
timerLabel.BackgroundTransparency = 1
timerLabel.Parent = screenGui

timerLabel.Text = "00:00.00"

local coinLabel = Instance.new("TextLabel")
coinLabel.Name = "CoinLabel"
coinLabel.Size = UDim2.new(0, 160, 0, 44)
coinLabel.Position = UDim2.fromScale(0.02, 0.04)
coinLabel.TextScaled = true
coinLabel.Font = config.Interface.Font
coinLabel.TextColor3 = config.Interface.TextColor
coinLabel.TextStrokeColor3 = config.Interface.StrokeColor
coinLabel.TextStrokeTransparency = 0
coinLabel.BackgroundTransparency = 1
coinLabel.Text = "Coins: 0"
coinLabel.Parent = screenGui

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(0, 400, 0, 40)
statusLabel.Position = UDim2.fromScale(0.5, 0.13)
statusLabel.AnchorPoint = Vector2.new(0.5, 0)
statusLabel.TextScaled = true
statusLabel.Font = config.Interface.Font
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.TextStrokeColor3 = config.Interface.StrokeColor
statusLabel.TextStrokeTransparency = 0
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Roll to the finish!"
statusLabel.Parent = screenGui

local function updateTimer(seconds)
    local minutes = math.floor(seconds / 60)
    local remainder = seconds - minutes * 60
    timerLabel.Text = string.format("%02d:%05.2f", minutes, remainder)
end

local function handleTimerBroadcast(mode, value, coins)
    if mode == "Tick" then
        updateTimer(value)
    elseif mode == "Reset" then
        updateTimer(0)
        coinLabel.Text = "Coins: 0"
    elseif mode == "Checkpoint" then
        coinLabel.Text = string.format("Coins: %d", coins)
    end
end

local function handleCoinCollected(total)
    coinLabel.Text = string.format("Coins: %d", total)
end

remotes.TimerBroadcast.OnClientEvent:Connect(handleTimerBroadcast)
remotes.CoinCollected.OnClientEvent:Connect(handleCoinCollected)

statusValue:GetPropertyChangedSignal("Value"):Connect(function()
    statusLabel.Text = statusValue.Value
end)

statusLabel.Text = statusValue.Value ~= "" and statusValue.Value or statusLabel.Text
