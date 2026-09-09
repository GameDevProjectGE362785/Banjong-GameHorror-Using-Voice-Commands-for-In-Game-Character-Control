# Game Project GE – Project Status

## Overview

This project is a Godot 4.7 first-person horror prototype focused on interactive object collection, inventory use, and factory power restoration. The main gameplay loop currently supports movement, interaction, item pickup, inventory management, and a fuse-based blackout restoration system.

## Implemented Systems

### Player and Movement
- First-person player controller using `CharacterBody3D`
- WASD movement and mouse-look camera control
- Gravity and floor collision
- Flashlight toggle independent from the factory lighting system
- Forward raycast interaction checks for nearby interactive objects

### Inventory and Interaction
- Inventory system using item names instead of direct scene references
- Item pickup from interactive objects in front of the player
- Inventory slot selection and item use
- Dropping selected inventory items in a safe position in front of the player
- Basic item use flow through the shared `itemClass` interface

### Items
- `Box`
- `Fuse`
- `Wrench`
- Each item exposes a shared interaction API and can be picked up and used in the world

### Factory Power Loop
- Map lighting starts in blackout state
- Factory lights remain off until the required number of fuses are inserted
- The electric box accepts fuses and tracks inserted count
- Once all required fuses are inserted, power is restored
- Player flashlight continues to function even during blackout

### Interaction Targets
- `ElectricBox` is wired to accept fuse items
- The system supports item-based interaction targeting without requiring direct object references in the inventory

## Key Files

- [player/player.gd](../player/player.gd) – player movement, interaction, inventory, use, drop, flashlight
- [Asset/interactiveItem.gd](../Asset/interactiveItem.gd) – shared item interaction contract
- [Asset/electricBox/electric_box.gd](../Asset/electricBox/electric_box.gd) – fuse insertion and power-state logic
- [Asset/LightingSystem/lighting_system.gd](../Asset/LightingSystem/lighting_system.gd) – blackout and factory lighting state
- [project.godot](../project.godot) – input mapping and project configuration

## Current Progress

### Completed
- Player movement and camera
- Item pickup
- Inventory and selection
- Item use and item drop
- Safe drop placement
- Fuse-based power restoration
- Factory blackout state
- Flashlight independence from world lighting
- Documentation updates in the instructions folder

### Remaining / Not Yet Implemented
- Wrench repair objective
- Box delivery objective
- Objective tracker and quest flow
- Full horror story progression
- Voice input / speech-to-text integration
- Dead bulb zone gameplay logic
- Final narrative finale and win/lose state flow

## Notes

This documentation reflects the current state of the prototype and acts as a handover reference for the next implementation step. The project already contains a working base for player interaction and power mechanics, and it is ready for the next stage of content and objective development.
