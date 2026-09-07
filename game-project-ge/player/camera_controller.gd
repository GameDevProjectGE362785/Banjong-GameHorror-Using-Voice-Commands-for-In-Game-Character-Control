extends Node3D

const MOUSE_SENSITIVITY = 0.003
const MIN_PITCH = -90.0
const MAX_PITCH = 90.0

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Rotate only up/down (pitch) — the Player handles left/right
		rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		rotation.x = clamp(rotation.x, deg_to_rad(MIN_PITCH), deg_to_rad(MAX_PITCH))
