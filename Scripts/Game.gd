extends Node2D

@export_dir var recipes_dir: String = "res://Ressources/"

@onready var world_node = $Background # Or create a dedicated 'World' node

func _ready():
	# Register this world to Global
	Global.current_world = self
	
	_load_habitat_recipes()
	Global.placeable_item_placed.connect(_on_placeable_item_placed)

func _on_placeable_item_placed(item):
	print("[Game] Signal received: Placeable item placed, checking habitat...")
	HabitatManager.check_for_new_habitat(item)

func _load_habitat_recipes():
	var recipes: Array[HabitatData] = []
	var path = recipes_dir
	var files = Utils.get_files_recursive(path, ".tres")
	
	for file_path in files:
		var res = load(file_path)
		if res is HabitatData:
			recipes.append(res)
	
	HabitatManager.habitat_recipes = recipes
	print("[Game] Loaded ", recipes.size(), " habitat recipes recursively.")

func _process(_delta):

	# Request redraw if we are currently placing an item to show the grid
	if PlaceableItemManager.current_placing_item != null:
		queue_redraw()

func _draw():
	if PlaceableItemManager.current_placing_item != null:
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
