# GameProjectGE - Current Overview

## Summary

Godot 4.7 3D prototype using the Forward+ renderer and Jolt Physics. The configured game entry point is `Test/Test.tscn`.

Current playable behavior:

- First-person camera attached to a `CharacterBody3D` player.
- WASD, arrow keys, or mapped controller input moves the player.
- Mouse movement controls view direction.
- `Esc` releases the mouse; clicking captures it again.
- Gravity is enabled; jumping is currently commented out.
- The Player RayCast detects `itemClass` objects in front of the camera.
- `F` picks up Box, Fuse, and Wrench props, or uses the selected Inventory item on a targeted object.
- `E` toggles the Inventory panel; `1`-`6` select an occupied slot.
- `Q` drops the selected Inventory item in front of the Player.
- `G` toggles the flashlight.

The repository name references voice-command character control, but no voice-recognition or command-processing code is currently present in this project snapshot.

## Project Structure

```text
.
├── project.godot              # Godot project settings, input actions, main scene
├── icon.svg                    # Project icon
├── player/
│   ├── player.tscn             # Reusable first-person player scene
│   ├── player.gd               # Movement, pickup, inventory, item use, flashlight
│   ├── camera_controller.gd    # Camera pitch controller
│   └── test.tscn               # Minimal empty Control test scene
├── Test/
│   └── Test.tscn               # Current main scene: floor + player instance
├── Asset/
│   ├── Box/Box.tscn            # Static cardboard box with collision
│   ├── Wrench/Wrench.tscn      # Static wrench with collision
│   └── Fuse/Fuse.tscn          # Static fuse with collision
│       └── Model/FuseModel.tscn # Procedural fuse mesh and materials
├── model/                      # Imported factory/environment GLB and textures
├── UI/                         # Interaction prompt and Inventory panel
├── instructions/               # Project notes and system handover documentation
├── .godot/                     # Godot editor/import cache (ignored)
└── *.import                    # Godot import metadata for source assets
```

## Scene Composition

### Main scene: `Test/Test.tscn`

- Root: `Node3D` named `Test`
- Floor: scaled `StaticBody3D` with a plane mesh and box collision
- Player: instance of `player/player.tscn`, positioned above the floor

### Player: `player/player.tscn`

- `CharacterBody3D` root
- Capsule collision and capsule mesh
- `CameraController` node for vertical camera rotation
- Current `Camera3D`
- Forward `RayCast3D`, available for future interaction targeting

### Reusable props

- `Box/Box.tscn`: imported cardboard box plus box collision
- `Wrench/Wrench.tscn`: imported wrench model plus box collision
- `Fuse/Fuse.tscn`: custom fuse model plus cylinder collision

## Important Configuration

- Project name: `GameProjectGE`
- Main scene: `res://Test/Test.tscn`
- Renderer: Forward+
- Physics: Jolt Physics
- Window stretch mode: canvas items, aspect expand
- Input actions: movement plus `PickUp`, `inventory`, `drop_item`, and `flashlight`
- Project icon: `res://icon.svg`

## Current Gaps

- Voice input and speech-to-command mapping are not implemented.
- The imported factory model is not referenced by the current main scene.
- Pickup, Inventory UI, item selection, item use hooks, and item dropping are implemented.
- The current test map includes one Box, one Wrench, four Fuse items, and the real Electric Box model for testing.
- No repair machine or delivery point currently overrides `use_item(item_name)`.
- `ElectricBox` accepts four `Fuse` items, then restores the `LightingSystem` to `NORMAL` and shows a green status light.
- Map lights start off and are restored by the Electric Box; the Player flashlight remains independent.
- No objective tracker consumes successful Fuse, Wrench, or Box actions yet.
- The Player stores item names rather than original item nodes; dropped items are recreated from their PackedScenes.
- The Player does not currently show a held-item model.
- Jumping code exists in `player.gd` but is disabled.

For the complete Player and item handover, see `instructions/PLAYER_ITEM_SYSTEM.md`.
For the implementation history and Git naming suggestions, see `instructions/IMPLEMENTATION_LOG.md`.

## Key Files

- `project.godot` - project settings and input bindings
- `Test/Test.tscn` - configured startup scene
- `player/player.gd` - player movement and horizontal look
- `player/camera_controller.gd` - vertical look
- `player/player.tscn` - first-person player composition
