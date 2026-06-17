extends Node2D

var current_placing_item = null
var habitat_manager: HabitatManager

@onready var world_node = $Background # Or create a dedicated 'World' node

func _ready():
	habitat_manager = HabitatManager.new(self)
	_load_habitat_recipes()
	Global.furniture_placed.connect(_on_furniture_placed)

func _on_furniture_placed(item):
	print("[Game] Signal received: Furniture placed, checking habitat...")
	habitat_manager.check_for_new_habitat(item)

func _load_habitat_recipes():
	var recipes: Array[HabitatData] = []
	var path = "res://Ressources/"
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var full_path = path + file_name
				var res = load(full_path)
				if res is HabitatData:
					recipes.append(res)
			file_name = dir.get_next()
	else:
		print("[Game] Error: Could not open path ", path)
	
	habitat_manager.habitat_recipes = recipes
	print("[Game] Loaded ", recipes.size(), " habitat recipes.")

func _on_crafting_menu_item_crafted(item_node):
	if current_placing_item != null:
		# If already placing something, maybe cancel it or just replace?
		# For now, let's just allow one at a time.
		current_placing_item.queue_free()
	
	current_placing_item = item_node
	add_child(current_placing_item)
	print("Started placement of ", item_node.name)

func _process(_delta):
	if current_placing_item != null:
		current_placing_item.global_position = Global.snap_to_grid(get_global_mouse_position())
		
		if is_position_valid():
			current_placing_item.modulate = Color(1, 1, 1, 0.5)
		else:
			current_placing_item.modulate = Color(1, 0, 0, 0.5)
			
		queue_redraw()

func is_position_valid() -> bool:
	if current_placing_item == null: return true
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	
	var collision_node = current_placing_item.get_node_or_null("CollisionShape2D")
	if not collision_node: return true
	
	query.shape = collision_node.shape
	query.transform = current_placing_item.global_transform
	query.exclude = [current_placing_item.get_rid()]
	
	var results = space_state.intersect_shape(query)
	return results.size() == 0

func _draw():
	if current_placing_item != null:
		draw_grid()

func draw_grid():
	var camera_pos = get_global_mouse_position() # Center around mouse for efficiency
	
	var start_x = int(camera_pos.x - 200) / Global.grid_size * Global.grid_size
	var end_x = int(camera_pos.x + 200) / Global.grid_size * Global.grid_size
	var start_y = int(camera_pos.y - 200) / Global.grid_size * Global.grid_size
	var end_y = int(camera_pos.y + 200) / Global.grid_size * Global.grid_size
	
	for x in range(start_x, end_x + Global.grid_size, Global.grid_size):
		draw_line(Vector2(x, start_y), Vector2(x, end_y), Color(1, 1, 1, 0.2), 1.0)
	for y in range(start_y, end_y + Global.grid_size, Global.grid_size):
		draw_line(Vector2(start_x, y), Vector2(end_x, y), Color(1, 1, 1, 0.2), 1.0)

func _input(event):
	if current_placing_item != null:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if is_position_valid():
				finalize_placement()
			else:
				print("Cannot place here - space occupied!")
		elif event.is_action_pressed("ui_cancel"): # Press ESC to cancel placement
			cancel_placement()

func finalize_placement():
	if current_placing_item.has_method("place"):
		current_placing_item.place()
		# Only emit the signal AFTER the item is successfully placed and validated
		Global.furniture_placed.emit(current_placing_item)
		print("Placed ", current_placing_item.name)
		current_placing_item = null
	else:
		print("Error: Item does not have a 'place' method")

func cancel_placement():
	if current_placing_item != null:
		# Optionally refund resources here?
		current_placing_item.queue_free()
		current_placing_item = null
		print("Placement cancelled")
