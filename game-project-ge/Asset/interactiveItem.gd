extends StaticBody3D

class_name itemClass

func getInteractive() -> String:
	return "null"

func get_item_name() -> String:
	return "Item"

func on_picked_up(_player: CharacterBody3D) -> void:
	pass

func use_item(_item_name: String) -> bool:
	return false
