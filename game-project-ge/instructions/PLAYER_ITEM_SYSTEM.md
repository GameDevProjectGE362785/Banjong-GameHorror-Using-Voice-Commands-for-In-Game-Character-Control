# Player and Item System

This document describes the Player, pickup, inventory, item use, and item drop systems currently implemented in the project.

## Controls

| Key | Action |
| --- | --- |
| `WASD` / arrow keys | Move the Player |
| Mouse | Look around |
| `F` | Pick up a targeted item, or use the selected item on a targeted object |
| `E` | Open or close the Inventory panel |
| `1`-`6` | Select an occupied Inventory slot |
| `G` | Toggle the flashlight |
| `Esc` | Release the mouse |

## Main Files

- `player/player.gd` contains movement, raycast interaction, pickup, inventory selection, item use, and item dropping.
- `player/player.tscn` contains the Player, Camera3D, RayCast3D, flashlight, and CameraView UI.
- `UI/camera_view.gd` controls the interaction prompt and Inventory display.
- `UI/CameraView.tscn` contains the Inventory panel and labels.
- `Asset/interactiveItem.gd` is the base class for world items and usable targets.
- `Asset/Box/box.gd`, `Asset/Fuse/fuse.gd`, and `Asset/Wrench/wrench.gd` identify the three item types.
- `project.godot` contains the input actions.

## Pickup Flow

1. The Player RayCast checks the object in front of the camera.
2. The object must inherit from `itemClass`.
3. `pickup()` reads the item name using `get_item_name()`.
4. The name is added to the Inventory array.
5. `on_picked_up()` is called on the item.
6. The original world item is removed with `queue_free()`.
7. The Inventory UI is refreshed.

The Inventory currently stores item names (`String` values), not the original scene instances. The item scene is recreated when the item is dropped.

## Inventory

- Maximum capacity is six items.
- The selected slot is stored in `selected_inventory_index`.
- Empty slots cannot be selected.
- The Inventory UI marks the selected item with `>`.

## Using Items

When `F` is pressed while aiming at a non-item target, it calls `use_selected_item()`.

The selected item is only removed when the targeted object has a `use_item(item_name)` method and that method returns `true`.

The base implementation is in `Asset/interactiveItem.gd`:

```gdscript
func use_item(_item_name: String) -> bool:
    return false
```

A target object should override it and accept only the item it needs. Example:

```gdscript
func use_item(item_name: String) -> bool:
    if item_name == "Fuse":
        restore_power()
        return true
    return false
```

## Dropping Items

`Q` calls `drop_selected_item()` and drops the selected item in front of the Player. The dropped scene is aligned to the floor and can be picked up again.

- The selected item is looked up in `ITEM_SCENES`.
- A new `Box`, `Wrench`, or `Fuse` scene is instantiated.
- The forward ray stops the item before a wall, then a downward ray finds the floor.
- The rendered `VisualInstance3D` bounds are used to offset the origin so the visible model sits above the floor.
- If no valid floor is found, the item is not removed from the Inventory.
- The item is removed from the Inventory.
- The dropped item can be picked up again.

## Item Types

The item scripts currently provide their interaction text and names:

| Script | Inventory name | Current gameplay behavior |
| --- | --- | --- |
| `Asset/Fuse/fuse.gd` | `Fuse` | Pickup and Electric Box power restoration |
| `Asset/Wrench/wrench.gd` | `Wrench` | Pickup only; no machine target yet |
| `Asset/Box/box.gd` | `Box` | Pickup only; no delivery target yet |

## Remaining Work

The following gameplay-specific targets still need to be created:

- A machine that accepts `Wrench` and changes its repaired state.
- A delivery point that accepts `Box` and completes the delivery objective.
- Objective tracking for collected and successfully used items.
- A held-item model, if the Player should visibly carry an item.
- Drop-position collision checking, if dropped items must never appear inside walls or other objects.

## Important Notes

- The old `haveItem` boolean is no longer used. Inventory capacity is checked with `inventory.size()` so multiple items can be carried.
- Item scenes must remain mapped in `ITEM_SCENES` if new item types are added; otherwise the new item cannot be dropped.
- The Player RayCast must continue to detect the collision layer used by item and target objects.
- World item scenes use collision Layer 2; the floor uses Layer 1 so drop-position floor rays do not hit other items.
- `Asset/electricBox/electric_Box.tscn` is the implemented use target. Aim at it and press `F` while a `Fuse` is selected. Four Fuse items are required before power is restored.
- The real Electric Box model in `Asset/electricBox/electric_Box.tscn` uses collision Layer 2 so the Player RayCast can target it.
- The map lights start in `BLACKOUT` and remain off until a `Fuse` is used on the Electric Box. This does not disable the Player flashlight.
- The opening beat is treated as 12:00 in the story; the current `GameClock` represents it internally as hour `0`.
- After all four Fuses are inserted, factory power is restored permanently for the rest of the run.
- For the full implementation history and suggested Git names, see `instructions/IMPLEMENTATION_LOG.md`.
