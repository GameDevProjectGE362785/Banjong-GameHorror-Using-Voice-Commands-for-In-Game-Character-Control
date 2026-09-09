# Implementation Log

This file records the Player, item, Inventory, factory-power, and item-drop work completed in this project snapshot.

## Completed Work

### Player interaction

- Kept the existing first-person `CharacterBody3D` Player movement and camera controls.
- Used the forward `RayCast3D` under `Player/CameraController` to find objects in front of the camera.
- Added item interaction checks through the shared `itemClass` base class.
- `F` picks up a targeted item or uses the selected Inventory item on a targeted use object.

### Pickup

- Implemented `pickup(item)` in `player/player.gd`.
- Pickup reads the item name through `get_item_name()`.
- The item name is appended to the Player Inventory.
- `on_picked_up(player)` is called before the world item is removed.
- The original item node is removed with `queue_free()`.
- The Inventory UI is refreshed after pickup.
- Pickup is blocked when the Inventory has six items.

### Inventory

- Added a six-slot Inventory using `Array[String]`.
- Added `selected_inventory_index` for the selected slot.
- `E` opens and closes the Inventory panel.
- Number keys `1` through `6` select occupied slots.
- The selected slot is shown with `>` in the Inventory UI.
- The Inventory stores item names rather than live scene nodes.

### Item types

The project currently supports these item names and scenes:

| Item | Script | Scene |
| --- | --- | --- |
| `Fuse` | `Asset/Fuse/fuse.gd` | `Asset/Fuse/Fuse.tscn` |
| `Wrench` | `Asset/Wrench/wrench.gd` | `Asset/Wrench/Wrench.tscn` |
| `Box` | `Asset/Box/box.gd` | `Asset/Box/Box.tscn` |

Each item inherits from `Asset/interactiveItem.gd` and provides its own interaction text and item name.

### Use item

- Added `use_selected_item()` to the Player.
- `F` attempts to use the selected item when the targeted object is not a pickup item.
- A target must implement `use_item(item_name) -> bool`.
- The Inventory item is removed only when the target returns `true`.
- Failed use attempts keep the item in the Inventory.
- The base `itemClass` implementation returns `false` so unsupported targets cannot consume items accidentally.

The first gameplay-specific target is implemented:

- `Asset/electricBox/electric_box.gd` accepts only `Fuse`.
- Four Fuse items are required before the factory power is restored.
- The Electric Box reports progress as `Insert Fuse (0/4)` through `Insert Fuse (3/4)`.
- After the fourth Fuse, it reports `Power Restored` and changes the status light to green.

### Drop item

- Added `drop_selected_item()` to the Player.
- `Q` drops the currently selected item.
- The item scene is recreated from the `ITEM_SCENES` map.
- The dropped item is placed in front of the Player.
- The selected item is removed from the Inventory only after a valid drop position is found.
- Dropped items can be picked up again.

### Drop-position fixes

Several placement issues were fixed during implementation:

1. The first drop implementation used a fixed position in front of the camera, which allowed items to enter walls or fall below the floor.
2. A forward physics ray was added to stop placement before a wall.
3. A downward physics ray was added to find the floor.
4. The rendered mesh bounds are used to align the visible model with the floor. This handles different origins and sizes for Box, Wrench, and Fuse.
5. Unsupported `Shape3D.get_aabb()` usage was removed. The final implementation uses `VisualInstance3D.get_aabb()` for rendered meshes.
6. Item scenes were changed from collision Layer 3 to Layer 2. The floor remains on Layer 1, so the floor ray cannot mistake another item for the floor.
7. If no valid floor is found, the drop is cancelled and the Inventory item is preserved.
8. Explicit GDScript types were added where raycast results return `Variant`, preventing warnings-as-errors parse failures.

## Controls

| Key | Action |
| --- | --- |
| `WASD` / arrows | Move |
| Mouse | Look |
| `F` | Pick up targeted item or use selected item on a target |
| `E` | Open/close Inventory |
| `1`-`6` | Select Inventory slot |
| `G` | Toggle flashlight |
| `Esc` | Release mouse |

Item dropping is enabled again. `Q` calls `drop_selected_item()` and drops the selected item in front of the Player.

### Factory lighting and Fuse objective

- `LightingSystem` starts in `BLACKOUT` at the opening story beat, treated as 12:00 by the design.
- `MapLightBlubs` listens to `LightingSystem` and hides all factory map lights during blackout.
- The Player flashlight is independent from factory lighting and can still be toggled with `G`.
- `temp/test_map.tscn` contains four Fuse instances and the real Electric Box model.
- The Electric Box restores `LightingSystem` to `NORMAL` only after all four Fuses are used.
- `LightingSystem.power_restored` prevents later blackout requests from turning the restored factory lights off.

## Files Changed for These Systems

- `player/player.gd`
- `Asset/interactiveItem.gd`
- `Asset/Box/box.gd`
- `Asset/Box/Box.tscn`
- `Asset/Fuse/fuse.gd`
- `Asset/Fuse/Fuse.tscn`
- `Asset/Wrench/wrench.gd`
- `Asset/Wrench/Wrench.tscn`
- `Asset/electricBox/electric_box.gd`
- `Asset/electricBox/electric_Box.tscn`
- `Asset/LightingSystem/lighting_system.gd`
- `Asset/MapLight/map_light_blubs.gd`
- `temp/test_map.tscn`
- `UI/camera_view.gd`
- `UI/CameraView.tscn`
- `project.godot`
- `instructions/CURRENT_PROJECT_OVERVIEW.md`
- `instructions/PLAYER_ITEM_SYSTEM.md`
- `instructions/IMPLEMENTATION_LOG.md`

## Not Implemented Yet

- Visible held-item models in the Player's hand.
- Machine repair gameplay for Wrench.
- Delivery gameplay for Box.
- Objective tracking for successful item use.
- Drop placement overlap test against walls and nearby objects.
- Voice-command input and command mapping.
- Full objective/event integration beyond the Fuse power objective.

## Git Naming Suggestions

### Branch name

Use a short feature branch name:

```text
feature/player-inventory-items
```

Alternative branches for follow-up work:

```text
feature/item-use-targets
fix/item-drop-placement
feature/objectives-and-delivery
```

### Commit message

For the completed Player, Inventory, use, drop, and collision-layer work:

```text
feat: add player inventory pickup use and drop system
```

For the drop-placement correction specifically:

```text
fix: prevent dropped items from floating or entering walls
```

For the documentation update:

```text
docs: document player and item systems
```

If the team prefers one commit for everything in this snapshot, use:

```text
feat: implement player item interaction system
```

### Suggested commit sequence

If commits are kept separated by purpose:

```text
feat: add item pickup and six-slot inventory
feat: add selected item usage
feat: add item dropping and safe placement
fix: separate item and floor collision layers
docs: document player and item systems
```

## Validation Status

- VS Code diagnostics reported no errors in the changed Player, UI, project settings, and documentation files.
- The project should still be tested in the Godot editor by picking up each item, selecting it, using it, dropping it, and picking it up again.
- The Godot executable was not available in the terminal PATH during this work, so a headless Godot run was not available.
