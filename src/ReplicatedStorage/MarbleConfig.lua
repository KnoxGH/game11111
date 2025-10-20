--[=[
MarbleConfig.lua

Shared configuration module for the Marble Roll game. Place this ModuleScript
inside ReplicatedStorage and require it from both server and client code.
]=]

local config = {}

-- Physical properties applied to each player marble.
config.Marble = {
    Radius = 3,
    Friction = 0.2,
    Density = 0.9,
    AngularDamping = 0.25,
    LinearDamping = 0.1,
    MaxSpeed = 110,
    ForceScale = 6000,
    JumpImpulse = 150,
    Elasticity = 0.05,
    FrictionWeight = 1,
}

-- Lighting setup for a bright, clean look.
config.Lighting = {
    Ambient = Color3.fromRGB(180, 205, 255),
    OutdoorAmbient = Color3.fromRGB(128, 152, 200),
    Brightness = 3,
}

-- Course layout definitions used by the server script to build the map.
config.Course = {
    SpawnPosition = Vector3.new(0, 25, 0),
    Checkpoints = {
        {
            Name = "Checkpoint01",
            Position = Vector3.new(150, 30, 0),
            Radius = 12,
        },
        {
            Name = "Checkpoint02",
            Position = Vector3.new(280, 45, -80),
            Radius = 12,
        },
        {
            Name = "Checkpoint03",
            Position = Vector3.new(420, 55, 60),
            Radius = 12,
        },
        {
            Name = "Finish",
            Position = Vector3.new(560, 60, 0),
            Radius = 15,
            IsFinish = true,
        },
    },
    CoinCount = 60,
    CoinSpread = Vector3.new(550, 30, 120),
}

-- HUD styling for the timer/score display.
config.Interface = {
    Font = Enum.Font.GothamBold,
    TextColor = Color3.fromRGB(255, 255, 255),
    StrokeColor = Color3.fromRGB(25, 25, 25),
    StrokeThickness = 1.7,
}

--
-- Returns a copy of the default marble material so individual marbles can tweak
-- colors without mutating the shared table.
--
function config:GetDefaultMaterial()
    return {
        Material = Enum.Material.Neon,
        Color = Color3.fromRGB(60, 165, 255),
        TrailColor = Color3.fromRGB(60, 255, 214),
    }
end

return config
