extends Node3D

class_name ElectricBox

@onready var status_light: OmniLight3D = get_node_or_null("StatusLight") as OmniLight3D
@onready var status_mesh: MeshInstance3D = get_node_or_null("StatusMesh") as MeshInstance3D

var powered := false
const REQUIRED_FUSES := 4
var inserted_fuses := 0

func _ready() -> void:
	_update_status()

func getInteractive() -> String:
	if powered:
		return "Power Restored"
	return "Insert Fuse (%d/%d)" % [inserted_fuses, REQUIRED_FUSES]

func use_item(item_name: String) -> bool:
	if powered or item_name != "Fuse" or inserted_fuses >= REQUIRED_FUSES:
		return false

	inserted_fuses += 1
	powered = inserted_fuses >= REQUIRED_FUSES
	_update_status()
	if powered and has_node("/root/LightingSystem"):
		LightingSystem.restore_factory_power()
	return true

func _update_status() -> void:
	if is_instance_valid(status_light):
		status_light.visible = powered
	if not is_instance_valid(status_mesh):
		return
	var material := status_mesh.get_active_material(0)
	if material is StandardMaterial3D:
		var status_material: StandardMaterial3D = material as StandardMaterial3D
		if powered:
			status_material.albedo_color = Color(0.15, 0.9, 0.25)
			status_material.emission_enabled = true
			status_material.emission = Color(0.1, 0.8, 0.2)
		else:
			status_material.albedo_color = Color(0.8, 0.08, 0.05)
			status_material.emission_enabled = false
