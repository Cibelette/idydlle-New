extends Node

# Reference to the world node where furniture should be added
var current_placing_item: Node2D = null
var all_furniture: Array[Node2D] = []
var opened_from_menu: String = ""

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

# Logical grid models: cell coordinate (Vector2i) -> item (Node2D)
var zone_grid: Dictionary = {}
var furniture_grid: Dictionary = {}

func _is_living_area(item: Node2D) -> bool:
	return item.get_script() != null and item.get_script().resource_path.contains("LivingArea.gd")

func get_occupied_cells_for_item(item: Node2D, custom_position: Vector2 = Vector2.ZERO) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	
	# Try to use CollisionShape2D if available for maximum physical layout accuracy
	var collision_node = item.get_node_or_null("CollisionShape2D")
	if collision_node and collision_node.shape is RectangleShape2D:
		var shape_size = collision_node.shape.size
		var center_pos = custom_position + collision_node.position if custom_position != Vector2.ZERO else collision_node.global_position
		
		# Round to cell units
		var size_cells_x = int(round(shape_size.x / Global.grid_size))
		var size_cells_y = int(round(shape_size.y / Global.grid_size))
		
		# Safety fallback to 1x1 if shape size is tiny
		if size_cells_x <= 0: size_cells_x = 1
		if size_cells_y <= 0: size_cells_y = 1
		
		var half_px_x = size_cells_x * (Global.grid_size / 2.0)
		var half_px_y = size_cells_y * (Global.grid_size / 2.0)
		
		var top_left_pos = center_pos - Vector2(half_px_x, half_px_y)
		var top_left_cell = Vector2i(
			round(top_left_pos.x / Global.grid_size),
			round(top_left_pos.y / Global.grid_size)
		)
		
		for dx in range(size_cells_x):
			for dy in range(size_cells_y):
				cells.append(top_left_cell + Vector2i(dx, dy))
		return cells
		
	# Fallback to furniture_data size if no CollisionShape2D is found
	var f_data = item.get("furniture_data")
	if not f_data or not "size" in f_data:
		return cells
		
	var size = f_data.size
	var pos = custom_position if custom_position != Vector2.ZERO else item.global_position
	
	var top_left_pos = pos - Vector2(size) * (Global.grid_size / 2.0)
	var top_left_cell = Vector2i(
		round(top_left_pos.x / Global.grid_size),
		round(top_left_pos.y / Global.grid_size)
	)
	
	for dx in range(size.x):
		for dy in range(size.y):
			cells.append(top_left_cell + Vector2i(dx, dy))
			
	return cells

func register_item(item: Node2D):
	var cells = get_occupied_cells_for_item(item)
	if cells.is_empty():
		return
		
	if _is_living_area(item):
		for cell in cells:
			zone_grid[cell] = item
		print("[GridManager] Registered Zone ", item.name, " at cells ", cells)
	else:
		for cell in cells:
			furniture_grid[cell] = item
		print("[GridManager] Registered Furniture ", item.name, " at cells ", cells)

func deregister_item(item: Node2D):
	var cells = get_occupied_cells_for_item(item)
	if cells.is_empty():
		return
		
	if _is_living_area(item):
		for cell in cells:
			if zone_grid.get(cell) == item:
				zone_grid.erase(cell)
		print("[GridManager] Deregistered Zone ", item.name, " from cells ", cells)
	else:
		for cell in cells:
			if furniture_grid.get(cell) == item:
				furniture_grid.erase(cell)
		print("[GridManager] Deregistered Furniture ", item.name, " from cells ", cells)

func is_position_valid(item: Node2D) -> bool:
	var cells = get_occupied_cells_for_item(item)
	if cells.is_empty():
		return true
		
	if _is_living_area(item):
		# Zones cannot overlap existing zones
		for cell in cells:
			var existing = zone_grid.get(cell)
			if is_instance_valid(existing) and existing != item:
				return false
	else:
		# Furniture cannot overlap existing furniture
		for cell in cells:
			var existing = furniture_grid.get(cell)
			if is_instance_valid(existing) and existing != item:
				return false
				
	return true

func finalize_placement():
	if current_placing_item.has_method("place"):
		var f_data = null
		if "furniture_data" in current_placing_item:
			f_data = current_placing_item.furniture_data
			
		current_placing_item.place()
		all_furniture.append(current_placing_item)
		
		if f_data:
			if current_placing_item.has_meta("is_direct_craft") and current_placing_item.get_meta("is_direct_craft"):
				if ResourcesManager.can_afford_multiple(f_data.costs):
					ResourcesManager.spend_multiple(f_data.costs)
				else:
					print("[FurnitureManager] Cannot place - resources no longer available!")
					cancel_placement()
					return
			else:
				ResourcesManager.spend_furniture(f_data, 1)
		
		# Emit global signal for compatibility
		Global.furniture_placed.emit(current_placing_item)
		
		print("[FurnitureManager] Placed ", current_placing_item.name)
		current_placing_item = null
		_reopen_menu()
	else:
		print("[FurnitureManager] Error: Item does not have a 'place' method")

func cancel_placement():
	if current_placing_item != null:
		current_placing_item.queue_free()
		current_placing_item = null
		print("[FurnitureManager] Placement cancelled")
		_reopen_menu()

func _reopen_menu():
	if opened_from_menu == "":
		return
		
	if is_instance_valid(Global.current_world):
		if opened_from_menu == "crafting":
			var craft_menu = Global.current_world.get_node_or_null("CanvasLayer/CraftingMenu")
			if craft_menu and craft_menu.has_method("show_menu"):
				craft_menu.show_menu()
		elif opened_from_menu == "inventory":
			var inv_menu = Global.current_world.get_node_or_null("CanvasLayer/InventoryMenu")
			if inv_menu and inv_menu.has_method("show_menu"):
				inv_menu.show_menu()
				
	opened_from_menu = ""

func get_all_furniture() -> Array[Node2D]:
	# Cleanup invalid references (queued for deletion)
	all_furniture = all_furniture.filter(func(f): return is_instance_valid(f))
	return all_furniture
