extends Node

# Reference to the world node where furniture should be added
var current_placing_item: Node2D = null
var all_furniture: Array[Node2D] = []

func _process(_delta):
	if current_placing_item != null:
		update_preview()
func update_preview():
	var size_px = Vector2(16, 16)
	if "furniture_data" in current_placing_item and current_placing_item.furniture_data:
		size_px = Vector2(current_placing_item.furniture_data.size) * Global.grid_size

	current_placing_item.global_position = Global.snap_to_grid(current_placing_item.get_global_mouse_position(), size_px)

	if is_position_valid(current_placing_item):
		current_placing_item.modulate = Color(1, 1, 1, 0.5)
	else:
		current_placing_item.modulate = Color(1, 0, 0, 0.5)

func start_placement(item_node: Node2D):
	if current_placing_item != null:
		cancel_placement()
	
	current_placing_item = item_node
	
	if is_instance_valid(Global.current_world):
		Global.current_world.add_child(current_placing_item)
	else:
		# Fallback to current scene if Global.current_world is not yet registered
		get_tree().current_scene.add_child(current_placing_item)
	
	print("[FurnitureManager] Started placement of ", item_node.name)

func _input(event):
	if current_placing_item != null:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if is_position_valid(current_placing_item):
				finalize_placement()
			else:
				print("[FurnitureManager] Cannot place here - space occupied!")
		elif event.is_action_pressed("ui_cancel"): # Press ESC to cancel placement
			cancel_placement()

func is_position_valid(item: Node2D) -> bool:
	var space_state = item.get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	
	var collision_node = item.get_node_or_null("CollisionShape2D")
	if not collision_node: 
		return true
	
	query.shape = collision_node.shape
	query.transform = item.global_transform
	query.exclude = [item.get_rid()]
	query.collision_mask = item.collision_layer # Only check against layers this item is on
	
	var results = space_state.intersect_shape(query)
	return results.size() == 0

func finalize_placement():
	if current_placing_item.has_method("place"):
		current_placing_item.place()
		all_furniture.append(current_placing_item)
		
		# Emit global signal for compatibility
		Global.furniture_placed.emit(current_placing_item)
		
		print("[FurnitureManager] Placed ", current_placing_item.name)
		current_placing_item = null
	else:
		print("[FurnitureManager] Error: Item does not have a 'place' method")

func cancel_placement():
	if current_placing_item != null:
		current_placing_item.queue_free()
		current_placing_item = null
		print("[FurnitureManager] Placement cancelled")

func get_all_furniture() -> Array[Node2D]:
	# Cleanup invalid references (queued for deletion)
	all_furniture = all_furniture.filter(func(f): return is_instance_valid(f))
	return all_furniture
