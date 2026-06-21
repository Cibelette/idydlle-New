extends Control

signal item_crafted(item_node)

@onready var crafting_panel = $CraftingPanel
@onready var item_list = $CraftingPanel/VBoxContainer

@export var craftable_items: Array[PlaceableItemData]

@export var base_placeable_item_scene: PackedScene = preload("res://Scenes/PlaceableItem.tscn")

func _ready():
	crafting_panel.visible = false
	setup_menu()

func setup_menu():
	# Clear existing placeholder buttons
	for child in item_list.get_children():
		if child is Button:
			child.queue_free()
	
	# Load all items from directory dynamically
	var items: Array[PlaceableItemData] = []
	var path = "res://Ressources/PlaceableItems/"
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			# Godot exported builds might append .remap to text resources, but ends_with(".tres") works in editor
			# We also check for ends_with(".tres.remap") for exported game compatibility
			if not dir.current_is_dir() and (file_name.ends_with(".tres") or file_name.ends_with(".tres.remap")):
				# Strip .remap suffix if present
				var clean_name = file_name.replace(".remap", "")
				var res = load(path + clean_name)
				if res is PlaceableItemData:
					items.append(res)
			file_name = dir.get_next()
		dir.list_dir_end()
	
	# Sort items alphabetically by name
	items.sort_custom(func(a, b): return a.name.nocasecmp_to(b.name) < 0)
	
	# Create buttons for each craftable item resource
	for item_data in items:
		if not item_data: continue
		
		var btn = Button.new()
		var cost_text = ""
		var costs = item_data.costs if item_data is FurnitureData else []
		for cost_item in costs:
			if cost_item:
				cost_text += "%d %s " % [cost_item.amount, Types.resource_to_string(cost_item.resource)]
		
		btn.text = "%s (%s)" % [item_data.name, cost_text.strip_edges()]
		btn.pressed.connect(func(): craft_item(item_data))
		item_list.add_child(btn)

func _input(event):
	if event.is_action_pressed("toggle_crafting"):
		toggle_menu()

func toggle_menu():
	crafting_panel.visible = !crafting_panel.visible

func _on_open_button_pressed():
	toggle_menu()

func show_menu():
	crafting_panel.visible = true

func craft_item(item_data: PlaceableItemData):
	# Check if we can afford all resources
	var costs = item_data.costs if item_data is FurnitureData else []
	if ResourcesManager.can_afford_multiple(costs):
		# Hide crafting panel
		crafting_panel.visible = false
		
		# Instantiate and start direct placement
		var scene_path = "res://Scenes/PlaceableItem_%dx%d.tscn" % [item_data.size.x, item_data.size.y]
		var target_scene = base_placeable_item_scene
		if item_data.custom_scene:
			target_scene = item_data.custom_scene
		elif ResourceLoader.exists(scene_path):
			target_scene = load(scene_path)

		var new_item = target_scene.instantiate()
		new_item.placeable_item_data = item_data
		new_item.set_meta("is_direct_craft", true)

		if "is_placed" in new_item:
			new_item.is_placed = false

		PlaceableItemManager.opened_from_menu = "crafting"
		PlaceableItemManager.start_placement(new_item)
		print("[Crafting] Proposed placement for: ", item_data.name)
	else:
		print("Not enough resources to craft ", item_data.name)
		
		
