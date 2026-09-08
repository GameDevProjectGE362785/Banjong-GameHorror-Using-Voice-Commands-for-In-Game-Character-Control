extends CharacterBody3D

@onready var raycast = $CameraController/RayCast3D
@onready var UI = $CameraView
@onready var flashlight = $CameraController/SpotLight3D
@onready var camera = $CameraController/Camera3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.003

const INVENTORY_SIZE := 6
const ITEM_SCENES := {
	"Box": preload("res://Asset/Box/Box.tscn"),
	"Wrench": preload("res://Asset/Wrench/Wrench.tscn"),
	"Fuse": preload("res://Asset/Fuse/Fuse.tscn")
}
var inventory: Array[String] = []
var selected_inventory_index := 0

var flashlighton = false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Connect to LightingSystem to handle flashlight state changes
	if has_node("/root/LightingSystem"):
		LightingSystem.lighting_state_changed.connect(_on_lighting_state_changed)
		# Sync initial flashlight state with current lighting
		_sync_flashlight_with_lighting()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Rotate the whole player body left/right (yaw)
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_6:
			select_inventory_slot(event.physical_keycode - KEY_1)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
	#	velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()


func _process(delta: float) -> void:
	checkObjectInfront()
	if Input.is_action_just_pressed("flashlight"):
		flashLightFunction()
	if Input.is_action_just_pressed("inventory"):
		UI.toggle_inventory()
	if Input.is_action_just_pressed("use_item"):
		use_selected_item()
	if Input.is_action_just_pressed("drop_item"):
		drop_selected_item()
	

func checkObjectInfront():
	if raycast.is_colliding():
		var item = raycast.get_collider()
		if item is itemClass:
			if inventory.size() < INVENTORY_SIZE:
				UI.TextChanger(item.getInteractive())
				UI.setCollition(true)
				if Input.is_action_just_pressed("PickUp"):
					pickup(item)
			else:
				UI.TextChanger("Inventory Full")
				UI.setCollition(true)
		else:
			UI.setCollition(false)
	else:
		UI.setCollition(false)

func pickup(item: itemClass) -> void:
	if inventory.size() >= INVENTORY_SIZE or not is_instance_valid(item):
		return

	var item_name := item.get_item_name()
	inventory.append(item_name)
	item.on_picked_up(self)
	item.queue_free()
	UI.update_inventory(inventory)
	UI.TextChanger("Picked up " + item_name)

func select_inventory_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= inventory.size():
		return

	selected_inventory_index = slot_index
	UI.update_inventory(inventory, selected_inventory_index)

func use_selected_item() -> void:
	if inventory.is_empty():
		UI.TextChanger("Inventory Is Empty")
		UI.setCollition(true)
		return
	if selected_inventory_index >= inventory.size():
		selected_inventory_index = inventory.size() - 1

	if not raycast.is_colliding():
		UI.TextChanger("Aim At An Object")
		UI.setCollition(true)
		return

	var target = raycast.get_collider()
	if not target.has_method("use_item"):
		UI.TextChanger("Cannot Use Item Here")
		UI.setCollition(true)
		return

	var item_name := inventory[selected_inventory_index]
	if target.use_item(item_name):
		inventory.remove_at(selected_inventory_index)
		selected_inventory_index = clamp(selected_inventory_index, 0, inventory.size() - 1)
		UI.update_inventory(inventory, selected_inventory_index)
		UI.TextChanger("Used " + item_name)
	else:
		UI.TextChanger("This Item Cannot Be Used Here")
	UI.setCollition(true)

func drop_selected_item() -> void:
	if inventory.is_empty():
		UI.TextChanger("Inventory Is Empty")
		UI.setCollition(true)
		return

	if selected_inventory_index >= inventory.size():
		selected_inventory_index = inventory.size() - 1

	var item_name := inventory[selected_inventory_index]
	if not ITEM_SCENES.has(item_name):
		UI.TextChanger("Cannot Drop " + item_name)
		UI.setCollition(true)
		return

	var dropped_item = ITEM_SCENES[item_name].instantiate()
	get_tree().current_scene.add_child(dropped_item)
	var drop_position: Variant = get_safe_drop_position(dropped_item)
	if drop_position == null:
		dropped_item.queue_free()
		UI.TextChanger("Cannot Drop Here")
		UI.setCollition(true)
		return
	dropped_item.global_position = drop_position
	inventory.remove_at(selected_inventory_index)
	selected_inventory_index = clamp(selected_inventory_index, 0, inventory.size() - 1)
	UI.update_inventory(inventory, selected_inventory_index)
	UI.TextChanger("Dropped " + item_name)
	UI.setCollition(true)

func get_safe_drop_position(dropped_item: Node3D) -> Variant:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var forward: Vector3 = -camera.global_transform.basis.z
	var ray_start: Vector3 = camera.global_position
	var ray_end: Vector3 = ray_start + forward * 1.5
	var forward_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	forward_query.exclude = [self]
	var forward_hit: Dictionary = space_state.intersect_ray(forward_query)
	var candidate: Vector3 = ray_end
	if not forward_hit.is_empty():
		var hit_position: Vector3 = forward_hit["position"]
		candidate = hit_position - forward * 0.35

	var floor_start: Vector3 = candidate + Vector3.UP * 2.0
	var floor_end: Vector3 = candidate + Vector3.DOWN * 2.0
	var floor_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(floor_start, floor_end)
	floor_query.collision_mask = 1
	floor_query.exclude = [self]
	var floor_hit: Dictionary = space_state.intersect_ray(floor_query)
	if floor_hit.is_empty():
		return null

	var floor_position: Vector3 = floor_hit["position"]
	dropped_item.global_position = Vector3(candidate.x, floor_position.y, candidate.z)
	var visual_bottom: float = get_visual_bottom(dropped_item)
	return dropped_item.global_position + Vector3.UP * (floor_position.y - visual_bottom + 0.02)

func get_visual_bottom(node: Node3D) -> float:
	var lowest_y: float = INF
	for child in node.get_children():
		if child is VisualInstance3D:
			var visual: VisualInstance3D = child as VisualInstance3D
			var bounds: AABB = visual.get_aabb()
			for x in [bounds.position.x, bounds.end.x]:
				for y in [bounds.position.y, bounds.end.y]:
					for z in [bounds.position.z, bounds.end.z]:
						var world_point: Vector3 = visual.global_transform * Vector3(x, y, z)
						lowest_y = minf(lowest_y, world_point.y)
		if child is Node3D:
			lowest_y = minf(lowest_y, get_visual_bottom(child as Node3D))
	return lowest_y

func flashLightFunction():
	# Check if flashlight is available based on LightingSystem
	if has_node("/root/LightingSystem") and not LightingSystem.is_flashlight_available():
		UI.TextChanger("Flashlight unavailable during blackout")
		return
	
	flashlighton = !flashlighton
	flashlight.visible = flashlighton


## Called when LightingSystem state changes
func _on_lighting_state_changed(new_state: int) -> void:
	# Turn off flashlight during blackout, regardless of previous state
	if new_state == LightingSystem.LightingState.BLACKOUT:
		flashlighton = false
		flashlight.visible = false
		UI.TextChanger("Lights cut out!")
	else:
		# Restore previous flashlight state when exiting blackout
		_sync_flashlight_with_lighting()


## Sync flashlight state with current lighting conditions
func _sync_flashlight_with_lighting() -> void:
	if has_node("/root/LightingSystem"):
		# Ensure flashlight is off during blackout
		if not LightingSystem.is_flashlight_available():
			flashlighton = false
			flashlight.visible = false


	
