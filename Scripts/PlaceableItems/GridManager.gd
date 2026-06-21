extends Node

# Logical grid models: cell coordinate (Vector2i) -> item (Node2D)
var zone_grid: Dictionary = {}
var placeable_grid: Dictionary = {}

func _is_living_area(item: Node2D) -> bool:
	return item is LivingArea

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
		
	# Fallback to placeable_item_data size if no CollisionShape2D is found
	var f_data = item.get("placeable_item_data")
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
			placeable_grid[cell] = item
		print("[GridManager] Registered Placeable ", item.name, " at cells ", cells)

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
			if placeable_grid.get(cell) == item:
				placeable_grid.erase(cell)
		print("[GridManager] Deregistered Placeable ", item.name, " from cells ", cells)

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
		# Placeable items cannot overlap existing placeables
		for cell in cells:
			var existing = placeable_grid.get(cell)
			if is_instance_valid(existing) and existing != item:
				return false
				
	return true
