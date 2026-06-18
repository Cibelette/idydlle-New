extends Control

signal item_crafted(item_node)

@onready var crafting_panel = $CraftingPanel
@onready var item_list = $CraftingPanel/VBoxContainer

@export var craftable_items: Array[FurnitureData]

var base_furniture_scene = preload("res://Scenes/Furniture.tscn")

func _ready():
	crafting_panel.visible = false
	setup_menu()

func setup_menu():
	# Clear existing placeholder buttons
	for child in item_list.get_children():
		if child is Button:
			child.queue_free()
	
	# Create buttons for each craftable item resource
	for item_data in craftable_items:
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

		# Build scene path based on size, e.g., Furniture_1x1.tscn
		var scene_path = "res://Scenes/Furniture_%dx%d.tscn" % [item_data.size.x, item_data.size.y]

		# Fallback to base furniture scene if specific size doesn't exist
		var target_scene = base_furniture_scene
		if item_data.custom_scene:
			target_scene = item_data.custom_scene
		elif ResourceLoader.exists(scene_path):
			target_scene = load(scene_path)

		var new_item = target_scene.instantiate()
		new_item.furniture_data = item_data

		if "is_placed" in new_item:

			new_item.is_placed = false
		
		# Start placement through the manager
		FurnitureManager.start_placement(new_item)
		
		item_crafted.emit(new_item)
		crafting_panel.visible = false
	else:
		print("Not enough resources to craft ", item_data.name)
		
		
