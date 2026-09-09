extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameClock.time_changed.connect(_on_game_clock_time_changed)

func _on_game_clock_time_changed(hour: int, minute: int) -> void:
	text = "%d : %d" % [hour,minute]
