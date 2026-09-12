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
	# KnockDetector เป็น Autoload (Global) แล้ว เข้าถึงตรงๆ ผ่านชื่อ ไม่ต้อง get_node
	Knockdetector.knock_detected.connect(_on_knock)
	Knockdetector.knock_sequence_completed.connect(_on_success)
	Knockdetector.knock_sequence_failed.connect(_on_fail)

	GameClock.hour_tick.connect(_on_hour_tick)

	# เชื่อม beat_triggered เข้ากับ event จริง (จุดที่ขาดไปก่อนหน้านี้)
	beat_triggered.connect(_on_beat_triggered)

	_on_hour_tick(GameClock.current_hour)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_K:
			print("=== TEST: เริ่มฟังเคาะ ===")
			Knockdetector.start_listening()
			
			
func _on_beat_triggered(hour: int, beat_id: StringName) -> void:
	match beat_id:
		&"intro_blackout":
			pass # TODO: ใส่ logic ของ beat นี้
		&"machine_check":
			pass
		&"delivery_arrival":
			pass
		&"clean_blood":
			pass
		&"fridge_ritual":
			pass
		&"dread_escalation":
			pass
		&"door_knock_finale":
			on_my_event_started()


func on_my_event_started() -> void:
	print("เคาะโต๊ะ 3 ครั้ง!")
	Knockdetector.start_listening()


func _on_knock(count: int) -> void:
	print("เคาะแล้ว")


func _on_success() -> void:
	print("สำเร็จ...")


func _on_fail() -> void:
	print("ล้มเหลว")


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
