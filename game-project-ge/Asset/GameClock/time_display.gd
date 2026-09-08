extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
func _on_game_clock_time_changed(hour: int, minute: int) -> void:
	text = "%d : %d" % [hour,minute]
