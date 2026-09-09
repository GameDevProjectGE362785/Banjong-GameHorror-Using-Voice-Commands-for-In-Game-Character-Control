extends Label

func _on_events_scheduler_beat_triggered(hour: int, beat_id: StringName) -> void:
	text = beat_id
