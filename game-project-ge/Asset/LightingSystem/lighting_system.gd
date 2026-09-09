## LightingSystem manages global lighting state for the game
## States: Normal (stable lights), Flicker (unstable), Blackout (lights off)
## Controls flashlight availability and emits signals on state changes
extends Node

signal lighting_state_changed(new_state: LightingState)

enum LightingState {
	NORMAL,
	FLICKER,
	BLACKOUT
}

# The factory lights stay off until the ElectricBox receives all Fuses.
var current_state := LightingState.BLACKOUT
var power_restored := false
var _flicker_timer := 0.0
var _flicker_interval := 0.1

## Development/testing: enable periodic blackouts every 30 in-game minutes
@export var enable_test_blackouts := false
var _last_blackout_minute := -1


func _ready() -> void:
	# Connect to GameClock to listen for hour changes if needed
	if has_node("/root/GameClock"):
		GameClock.hour_tick.connect(_on_hour_tick)
		if enable_test_blackouts:
			GameClock.time_changed.connect(_on_time_changed)


func _process(delta: float) -> void:
	if current_state == LightingState.FLICKER:
		_update_flicker(delta)


## Change the lighting state to a new state
func set_state(new_state: LightingState) -> void:
	if power_restored and new_state == LightingState.BLACKOUT:
		return
	if new_state == current_state:
		return
	
	current_state = new_state
	_reset_flicker()
	lighting_state_changed.emit(current_state)


## Get the current lighting state
func get_state() -> LightingState:
	return current_state


## Check if flashlight is available based on current lighting state
func is_flashlight_available() -> bool:
	# Flashlight is unavailable only during BLACKOUT
	return current_state != LightingState.BLACKOUT


## Check if we're in a specific state
func is_in_state(state: LightingState) -> bool:
	return current_state == state


func restore_factory_power() -> void:
	power_restored = true
	set_state(LightingState.NORMAL)


## Flicker the lights by rapidly toggling between NORMAL and a dim state
## This is handled by the flashlight's visual effect, not by state changes
func _update_flicker(delta: float) -> void:
	_flicker_timer += delta
	if _flicker_timer >= _flicker_interval:
		_flicker_timer = 0.0


## Reset flicker timing
func _reset_flicker() -> void:
	_flicker_timer = 0.0


## Called when GameClock ticks an hour
func _on_hour_tick(hour: int) -> void:
	# The first story beat represents 12:00:00, when the factory power is out.
	if hour == 0 and not power_restored:
		set_state(LightingState.BLACKOUT)


## Called when time changes (minute-level granularity)
## Used for test blackouts every 30 in-game minutes
func _on_time_changed(hour: int, minute: int) -> void:
	if not enable_test_blackouts:
		return
	
	# Trigger blackout every 30 minutes (at :00 and :30)
	if minute == 0 or minute == 30:
		# Avoid triggering twice on the same minute
		if minute != _last_blackout_minute:
			_last_blackout_minute = minute
			_trigger_test_blackout(hour, minute)
	# Reset when minute rolls past :30
	elif minute > 30:
		pass


## Trigger a test blackout sequence
func _trigger_test_blackout(hour: int, minute: int) -> void:
	print("TEST: Triggering blackout at %02d:%02d" % [hour, minute])
	set_state(LightingState.BLACKOUT)
	
	# Auto-restore after 3 seconds for continuous testing
	await get_tree().create_timer(3.0).timeout
	set_state(LightingState.NORMAL)
	print("TEST: Blackout ended, lights restored")


## Get a human-readable state name
func get_state_name() -> String:
	match current_state:
		LightingState.NORMAL:
			return "Normal"
		LightingState.FLICKER:
			return "Flicker"
		LightingState.BLACKOUT:
			return "Blackout"
		_:
			return "Unknown"
