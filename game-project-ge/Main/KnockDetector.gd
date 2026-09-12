extends Node

signal knock_detected(count: int)      # เคาะแต่ละครั้ง
signal knock_sequence_completed        # ครบ 3 ครั้ง
signal knock_sequence_failed           # หมดเวลา นับไม่ครบ

@export var bus_name: String = "Mic"
@export var required_knocks: int = 3
@export var threshold: float = 0.25      # ความดังขั้นต่ำ (0..1) ปรับตามไมค์
@export var release_threshold: float = 0.10  # ต้องเงียบต่ำกว่านี้ก่อนนับครั้งถัดไป
@export var cooldown: float = 0.12       # กันนับซ้ำจากเสียงก้อง (วินาที)
@export var sequence_timeout: float = 3.0 # ต้องเคาะครบ 3 ครั้งภายในกี่วิ

var _capture: AudioEffectCapture
var _active: bool = false
var _count: int = 0
var _cooldown_timer: float = 0.0
var _sequence_timer: float = 0.0
var _armed: bool = true   # true = พร้อมรับเคาะครั้งใหม่ (เสียงเงียบลงแล้ว)

func _ready() -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	print("Bus index for '%s': %d" % [bus_name, idx])
	if idx == -1:
		push_error("ไม่พบ bus ชื่อ %s" % bus_name)
		return
	for i in AudioServer.get_bus_effect_count(idx):
		var fx := AudioServer.get_bus_effect(idx, i)
		print("Effect %d: %s" % [i, fx])
		if fx is AudioEffectCapture:
			_capture = fx
			break
	print("_capture found: ", _capture != null)
	set_process(false)

## เรียกตอนอีเวนต์ของคุณเริ่ม
func start_listening() -> void:
	if _capture == null: return
	_capture.clear_buffer()
	_active = true
	_count = 0
	_cooldown_timer = 0.0
	_sequence_timer = 0.0
	_armed = true
	set_process(true)

func stop_listening() -> void:
	_active = false
	set_process(false)

func _process(delta: float) -> void:
	if not _active or _capture == null: return

	# --- timeout ของทั้งชุด ---
	_sequence_timer += delta
	if _sequence_timer > sequence_timeout:
		stop_listening()
		knock_sequence_failed.emit()
		return

	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta

	# --- อ่านค่าความดังสูงสุดใน buffer ---
	var frames := _capture.get_frames_available()
	if frames <= 0: return
	var buffer := _capture.get_buffer(frames)

	var peak := 0.0
	for f in buffer:
		peak = max(peak, max(absf(f.x), absf(f.y)))

	# --- ตรวจจับขอบขาขึ้น (onset) ---
	if _armed and peak >= threshold and _cooldown_timer <= 0.0:
		_armed = false
		_cooldown_timer = cooldown
		_count += 1
		knock_detected.emit(_count)
		if _count >= required_knocks:
			stop_listening()
			knock_sequence_completed.emit()
	elif not _armed and peak < release_threshold:
		_armed = true   # เสียงเงียบลงแล้ว พร้อมรับเคาะครั้งถัดไป
