extends Control

enum LightingState {
	NORMAL,
	FLICKER,
	BLACKOUT
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	LightingSystem.lighting_state_changed.connect(_on_light_state_changed)


func _on_light_state_changed(new_state: LightingState) -> void:\
	$VBoxContainer/LightState.text = "LightState : %s" % LightingState.find_key(new_state)
