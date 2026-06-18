# Roblox Marble Roll Game Scripts

This repository contains a complete set of Roblox Studio scripts for a physics-based marble rolling obstacle course. Drop the scripts into their respective services and publish the experience to play solo or cooperatively with friends.

## Contents

```
src/
├── ReplicatedStorage
│   └── MarbleConfig.lua
├── ServerScriptService
│   └── GameController.server.lua
├── StarterGui
│   └── TimerGui.client.lua
└── StarterPlayer
    └── StarterPlayerScripts
        └── MarbleController.client.lua
```

## Quick start

1. Open **Roblox Studio** and create a new *Baseplate* experience.
2. Import the files:
   * Place `MarbleConfig.lua` inside **ReplicatedStorage** as a ModuleScript.
   * Place `GameController.server.lua` inside **ServerScriptService** as a Script.
   * Place `MarbleController.client.lua` inside **StarterPlayer > StarterPlayerScripts** as a LocalScript.
   * Place `TimerGui.client.lua` inside **StarterGui** as a LocalScript.
3. Press **Play** from the **Test** tab (or click the green ▶️ button in the top toolbar). The server script will automatically generate a course, spawn a marble for every player, and broadcast run/timer data to all clients.

### Starting a playtest session later

If you reopen the place and want to jump straight into the marble experience:

1. Open the **Test** tab.
2. Click **Play** (or **Play Here** to spawn at your current camera position).
3. Wait for your camera to snap to the glowing marble—your Roblox avatar will be hidden underground while you roll.

## Features

- Fully procedural track with ramps, neon checkpoints, and a glowing finish pad.
- Responsive keyboard and gamepad controls using `VectorForce` and `AngularVelocity` movers.
- Camera follow system that keeps the action centered on your marble.
- Jump and manual respawn support (`Space`/`A` to jump, `R` to reset).
- Coin collection system with automatic coin spinning effects.
- Checkpoint tracking, status feed, and best-time leaderboard storage in `ServerStorage`.
- Cross-device HUD that displays timer, coin total, and server announcements.

## Customization

Tune the experience by editing the values exposed through `MarbleConfig.lua`:

- **Marble physics**: adjust `ForceScale`, `MaxSpeed`, or `JumpImpulse` for faster or slower runs.
- **Course layout**: move checkpoint vectors or add new entries to `config.Course.Checkpoints`.
- **Coin density**: tweak `CoinCount` and `CoinSpread` to change collectible placement.
- **Lighting**: change the ambient brightness and color in `config.Lighting`.
- **HUD style**: swap fonts and colors in `config.Interface`.

Enjoy rolling!

## Testing

These scripts are designed for Roblox Studio. To test the experience:

1. Open your place in Roblox Studio with the scripts inserted in the services listed above.
2. Click **Play** or **Play Here** to enter a local test session.
3. Verify that only your marble is visible, the camera follows it, and checkpoints/coins update the HUD.

Roblox Studio is required to simulate the physics objects and networking; automated testing is not available in this repository.
