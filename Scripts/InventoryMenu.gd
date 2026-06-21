extends Control

@onready var inventory_panel = $InventoryPanel
@onready var grid_container = $InventoryPanel/VBoxContainer/ScrollContainer/GridContainer
@onready var tab_all = $InventoryPanel/VBoxContainer/TabButtons/TabAll
@onready var tab_resources = $InventoryPanel/VBoxContainer/TabButtons/TabResources
@onready var tab_placeables = $InventoryPanel/VBoxContainer/TabButtons/TabPlaceables

# Preloads for base placeable scenes, similar to CraftingMenu.gd
@export var base_placeable_item_scene: PackedScene = preload("res://Scenes/PlaceableItem.tscn")

var current_tab: String = "All" # "All", "Resources", "Placeables"
var slots: Array[Control] = []

func _ready():
	inventory_panel.visible = false
	
	# Connect tab buttons
	tab_all.pressed.connect(func(): set_tab("All"))
	tab_resources.pressed.connect(func(): set_tab("Resources"))
	tab_placeables.pressed.connect(func(): set_tab("Placeables"))
	
	# Initialize 64 empty slots
	_create_slots()
	
	# Connect to ResourcesManager update signal
	ResourcesManager.inventory_updated.connect(refresh_grid)
	
	# Initial draw
	refresh_grid()

func _input(event):
	if event.is_action_pressed("toggle_inventory"):
		toggle_menu()

func toggle_menu():
	inventory_panel.visible = !inventory_panel.visible
	if inventory_panel.visible:
		refresh_grid()

func set_tab(tab_name: String):
	current_tab = tab_name
	_update_tab_button_styles()
	refresh_grid()

func _update_tab_button_styles():
	# Highlight the active tab button
	var active_color = Color(1.0, 1.0, 1.0, 1.0)
	var inactive_color = Color(0.7, 0.7, 0.7, 0.8)
	
	tab_all.modulate = active_color if current_tab == "All" else inactive_color
	tab_resources.modulate = active_color if current_tab == "Resources" else inactive_color
	tab_placeables.modulate = active_color if current_tab == "Placeables" else inactive_color

func _create_slots():
	# Clear any placeholders
	for child in grid_container.get_children():
		child.queue_free()
	slots.clear()
	
	# Create 64 slots
	for i in range(64):
		var slot_panel = PanelContainer.new()
		slot_panel.custom_minimum_size = Vector2(48, 48)
		
		# Give it a nice clean StyleBoxFlat style
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.10, 0.09, 0.85)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.25, 0.22, 0.20, 1.0)
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_right = 6
		style.corner_radius_bottom_left = 6
		slot_panel.add_theme_stylebox_override("panel", style)
		
		# Center container to host the icon
		var center_container = CenterContainer.new()
		center_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_panel.add_child(center_container)
		
		var texture_rect = TextureRect.new()
		texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_rect.custom_minimum_size = Vector2(32, 32)
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		center_container.add_child(texture_rect)
		
		# Control wrapper for the label in bottom right
		var count_container = MarginContainer.new()
		count_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		count_container.add_theme_constant_override("margin_right", 4)
		count_container.add_theme_constant_override("margin_bottom", 2)
		slot_panel.add_child(count_container)
		
		# Make it bottom-right aligned
		var label = Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		# Small font size
		label.add_theme_font_size_override("font_size", 12)
		
		# Add shadow or outline to label for readability
		label.add_theme_color_override("font_shadow_color", Color.BLACK)
		label.add_theme_constant_override("shadow_outline_size", 3)
		
		count_container.add_child(label)
		
		grid_container.add_child(slot_panel)
		slots.append(slot_panel)

func refresh_grid():
	if not is_inside_tree(): return
	
	# Fetch inventory items based on current tab
	var items_to_show = [] # Array of Dictionary: { "type": "resource"/"placeable", "data": Resource, "amount": int }
	
	# 1. Add resources if not in "Placeables" tab
	if current_tab == "All" or current_tab == "Resources":
		var resources = ResourcesManager.get_all_resources()
		for res_type in resources:
			var amount = resources[res_type]
			if amount > 0:
				var res_data = ResourcesManager.get_resource_data(res_type)
				if res_data:
					items_to_show.append({
						"type": "resource",
						"data": res_data,
						"amount": amount
					})
					
	# 2. Add placeables if not in "Resources" tab
	if current_tab == "All" or current_tab == "Placeables":
		var placeables = ResourcesManager.get_all_placeable_items()
		for furn_data in placeables:
			var amount = placeables[furn_data]
			if amount > 0:
				items_to_show.append({
					"type": "placeable",
					"data": furn_data,
					"amount": amount
				})
				
	# Sort items to show (resources first, then placeables, by name)
	items_to_show.sort_custom(func(a, b):
		if a.type != b.type:
			return a.type == "resource" # resources first
		return a.data.name.nocasecmp_to(b.data.name) < 0
	)
	
	# 3. Update the slots
	for i in range(64):
		var slot = slots[i]
		var texture_rect = slot.get_child(0).get_child(0)
		var label = slot.get_child(1).get_child(0)
		
		# Disconnect any previous clicks
		if slot.has_meta("click_callable"):
			var prev_callable = slot.get_meta("click_callable")
			if slot.gui_input.is_connected(prev_callable):
				slot.gui_input.disconnect(prev_callable)
			slot.remove_meta("click_callable")
		
		if i < items_to_show.size():
			var item = items_to_show[i]
			slot.tooltip_text = "%s\nAmount: %d" % [item.data.name, item.amount]
			
			# Set icon
			if item.type == "resource":
				texture_rect.texture = item.data.sprite
			else:
				texture_rect.texture = item.data.icon if item.data.icon else item.data.texture
				
			texture_rect.show()
			
			# Set count
			label.text = str(item.amount)
			label.show()
			
			# Interactive border styling for occupied slots
			var style = slot.get_theme_stylebox("panel").duplicate()
			if item.type == "placeable":
				# Give placeables a distinct border highlight (cozy terracotta/orange border)
				style.border_color = Color(0.839, 0.500, 0.459, 1.0)
				style.bg_color = Color(0.18, 0.14, 0.12, 0.9)
			else:
				# Resource border styling (cozy slate/beige border)
				style.border_color = Color(0.50, 0.45, 0.40, 1.0)
				style.bg_color = Color(0.14, 0.12, 0.11, 0.9)
			slot.add_theme_stylebox_override("panel", style)
			
			# Handle clicks for placeable placement
			if item.type == "placeable":
				var on_click = func(event):
					if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
						place_placeable_item(item.data)
				slot.gui_input.connect(on_click)
				slot.set_meta("click_callable", on_click)
				slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			else:
				slot.mouse_default_cursor_shape = Control.CURSOR_ARROW
		else:
			# Empty slot
			slot.tooltip_text = "Empty Slot"
			texture_rect.texture = null
			texture_rect.hide()
			label.text = ""
			label.hide()
			slot.mouse_default_cursor_shape = Control.CURSOR_ARROW
			
			# Dimmed border styling for empty slots
			var style = slot.get_theme_stylebox("panel").duplicate()
			style.border_color = Color(0.20, 0.18, 0.16, 1.0)
			style.bg_color = Color(0.10, 0.08, 0.07, 0.8)
			slot.add_theme_stylebox_override("panel", style)

func show_menu():
	inventory_panel.visible = true
	refresh_grid()

func place_placeable_item(item_data: PlaceableItemData):
	print("[InventoryMenu] Placing placeable: ", item_data.name)
	
	# Close the inventory menu
	inventory_panel.visible = false
	
	# Instantiate and place
	var scene_path = "res://Scenes/PlaceableItem_%dx%d.tscn" % [item_data.size.x, item_data.size.y]

	# Fallback to base placeable scene if specific size doesn't exist
	var target_scene = base_placeable_item_scene
	if item_data.custom_scene:
		target_scene = item_data.custom_scene
	elif ResourceLoader.exists(scene_path):
		target_scene = load(scene_path)

	var new_item = target_scene.instantiate()
	new_item.placeable_item_data = item_data

	if "is_placed" in new_item:
		new_item.is_placed = false
	
	# Start placement through the manager
	PlaceableItemManager.opened_from_menu = "inventory"
	PlaceableItemManager.start_placement(new_item)

func _on_close_button_pressed():
	toggle_menu()
