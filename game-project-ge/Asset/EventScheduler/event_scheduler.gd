extends Node

signal beat_triggered(hour: int, beat_id: StringName)

const BEATS: Dictionary = {
	0: &"intro_blackout",
	1: &"machine_check",
	2: &"delivery_arrival",
	3: &"clean_blood",
	4: &"fridge_ritual",
	5: &"dread_escalation",
	6: &"door_knock_finale",
}

var last_triggered_hour := -1
var triggered_beats: Array[StringName] = []


func _ready() -> void:
	GameClock.hour_tick.connect(_on_hour_tick)
	_on_hour_tick(GameClock.current_hour)


func get_beat_id(hour: int) -> StringName:
	return BEATS.get(hour, &"")

func has_beat(hour: int) -> bool:
	return BEATS.has(hour)

func trigger_beat(hour: int) -> void:
	_on_hour_tick(hour)


func reset() -> void:
	last_triggered_hour = -1
	triggered_beats.clear()
	_on_hour_tick(GameClock.current_hour)

func _on_hour_tick(hour: int) -> void:
	if hour == last_triggered_hour:
		return

	last_triggered_hour = hour
	var beat_id := get_beat_id(hour)
	if beat_id.is_empty():
		return

	triggered_beats.append(beat_id)
	beat_triggered.emit(hour, beat_id)
	print("EventScheduler: %02d:00 -> %s" % [hour, beat_id])
