extends Control

signal item_crafted(item_node)

@onready var crafting_panel = $CraftingPanel
@onready var item_list = $CraftingPanel/VBoxContainer

@export var craftable_items: Array[FurnitureData]

@export var base_furniture_scene: PackedScene = preload("res://Scenes/Furniture.tscn")

func _ready():
	crafting_panel.visible = false
	setup_menu()

func setup_menu():
	# Clear existing placeholder buttons
	for child in item_list.get_children():
		if child is Button:
			child.queue_free()
	
	# Load all items from directory dynamically
	var items: Array[FurnitureData] = []
	var path = "res://Ressources/Furnitures/"
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
				if res is FurnitureData:
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
		for cost_item in item_data.costs:
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

# Generic crafting function using Resource
func craft_item(item_data: FurnitureData):
	# Check if we can afford all resources
	if ResourcesManager.can_afford_multiple(item_data.costs):
		# Spend all resources
		ResourcesManager.spend_multiple(item_data.costs)

		# Add to player inventory
		ResourcesManager.add_furniture(item_data, 1)
		
		# Emitting placeholder for compatibility if needed
		# (We don't instantiate the scene here anymore, it's done when placing from inventory)
		
		print("[Crafting] Crafted and added to inventory: ", item_data.name)
		crafting_panel.visible = false
	else:
		print("Not enough resources to craft ", item_data.name)
		
		
