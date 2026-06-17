extends Control

signal item_crafted(item_node)

@onready var crafting_panel = $CraftingPanel
@onready var item_list = $CraftingPanel/VBoxContainer

@export var craftable_items: Array[FurnitureData]

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
		for res_type in item_data.costs:
			cost_text += "%d %s " % [item_data.costs[res_type], res_type]
		
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
			
		var new_item = item_data.scene.instantiate()
		if "furniture_data" in new_item:
			new_item.furniture_data = item_data
			
		if "is_placed" in new_item:
			new_item.is_placed = false
		
		# Start placement through the manager
		FurnitureManager.start_placement(new_item)
		
		item_crafted.emit(new_item)
		crafting_panel.visible = false
	else:
		print("Not enough resources to craft ", item_data.name)
		
		
