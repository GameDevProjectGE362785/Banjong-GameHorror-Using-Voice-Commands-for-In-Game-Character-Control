extends Control

@onready var TextHandler = $Control
@onready var paragraph = $Control/Label
@onready var inventory_panel = $InventoryPanel
@onready var inventory_label = $InventoryPanel/MarginContainer/VBoxContainer/InventoryLabel

var collitionOn = false

func _ready() -> void:
	inventory_panel.visible = false
	update_inventory([])

func setCollition(boolean : bool):
	collitionOn = boolean

func TextChanger(word : String) -> void:
	paragraph.text = word

func update_inventory(items: Array[String], selected_index: int = -1) -> void:
	var lines: Array[String] = []
	for index in range(6):
		var slot_number := index + 1
		var slot_text := "Empty"
		if index < items.size():
			slot_text = items[index]
		var marker := "  "
		if index == selected_index:
			marker = "> "
		lines.append("%s%d. %s" % [marker, slot_number, slot_text])
	inventory_label.text = "Inventory\n1-6 Select | F Use | Q Drop\n" + "\n".join(lines)

func toggle_inventory() -> void:
	inventory_panel.visible = not inventory_panel.visible

func _process(delta: float) -> void:
	if collitionOn:
		TextHandler.visible = true
	else:
		TextHandler.visible = false
