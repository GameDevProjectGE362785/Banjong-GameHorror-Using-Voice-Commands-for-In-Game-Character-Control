extends Node

var LightBlubs : Array[Node]
var lighting_system: Node
var _flicker_active := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	LightBlubs = get_children()
	
	# Get reference to LightingSystem
	if has_node("/root/LightingSystem"):
		lighting_system = get_node("/root/LightingSystem")
		# Connect to lighting state changes
		lighting_system.lighting_state_changed.connect(_on_lighting_state_changed)
		# Initialize with current state
		_on_lighting_state_changed(lighting_system.get_state())
	else:
		print("LightingSystem not found. MapLightBlubs will not respond to lighting changes.")


## Handle lighting state changes from LightingSystem
func _on_lighting_state_changed(new_state: int) -> void:
	match new_state:
		0:  # NORMAL
			_set_normal_lighting()
		1:  # FLICKER
			_set_flicker_lighting()
		2:  # BLACKOUT
			_set_blackout_lighting()


## Show all lights normally
func _set_normal_lighting() -> void:
	_flicker_active = false
	for blub in LightBlubs:
		blub.show()


## Activate flickering effect on lights
func _set_flicker_lighting() -> void:
	_flicker_active = true
	_light_flickering_randomly()


## Turn off all lights during blackout
func _set_blackout_lighting() -> void:
	_flicker_active = false
	for blub in LightBlubs:
		blub.hide()


## Randomly flicker lights by toggling visibility
func _light_flickering_randomly() -> void:
	while _flicker_active and lighting_system and lighting_system.is_in_state(1):  # FLICKER state
		if LightBlubs.is_empty():
			print("No LightBlubs found.")
			await get_tree().create_timer(0.5).timeout
			continue
		
		var blub: Node = LightBlubs[randi_range(0, LightBlubs.size() - 1)]
		if blub:
			blub.hide()
			await get_tree().create_timer(randf_range(0.1, 0.3)).timeout
			blub.show()
			await get_tree().create_timer(randf_range(0.2, 0.5)).timeout
		else:
			await get_tree().create_timer(0.5).timeout
