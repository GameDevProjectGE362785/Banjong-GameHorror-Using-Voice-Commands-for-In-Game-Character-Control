extends Control

@onready var TextHandler = $Control
@onready var paragraph = $Control/Label

var collitionOn = false

func setCollition(boolean : bool):
	collitionOn = boolean

func TextChanger(word : String) -> void:
	paragraph.text = word

func _process(delta: float) -> void:
	if collitionOn:
		TextHandler.visible = true
	else:
		TextHandler.visible = false
