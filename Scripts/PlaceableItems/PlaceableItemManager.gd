extends Node

# Reference to the world node where items should be added
var current_placing_item: Node2D = null
var all_placeable_items: Array[Node2D] = []
var opened_from_menu: String = ""

func _process(_delta):
	if current_placing_item != null:
		update_preview()

func update_preview():
	var size_px = Vector2(16, 16)
	if "placeable_item_data" in current_placing_item and current_placing_item.placeable_item_data:
		size_px = Vector2(current_placing_item.placeable_item_data.size) * Global.grid_size

	current_placing_item.global_position = Global.snap_to_grid(current_placing_item.get_global_mouse_position(), size_px)

	if GridManager.is_position_valid(current_placing_item):
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
	
	print("[PlaceableItemManager] Started placement of ", item_node.name)

func _input(event):
	if current_placing_item != null:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if GridManager.is_position_valid(current_placing_item):
				finalize_placement()
			else:
				print("[PlaceableItemManager] Cannot place here - space occupied!")
		elif event.is_action_pressed("ui_cancel"): # Press ESC to cancel placement
			cancel_placement()

func finalize_placement():
	if current_placing_item.has_method("place"):
		var p_data = null
		if "placeable_item_data" in current_placing_item:
			p_data = current_placing_item.placeable_item_data
			
		current_placing_item.place()
		all_placeable_items.append(current_placing_item)
		
		if p_data:
			if current_placing_item.has_meta("is_direct_craft") and current_placing_item.get_meta("is_direct_craft"):
				if ResourcesManager.can_afford_multiple(p_data.costs):
					ResourcesManager.spend_multiple(p_data.costs)
				else:
					print("[PlaceableItemManager] Cannot place - resources no longer available!")
					cancel_placement()
					return
			else:
				ResourcesManager.spend_placeable_item(p_data, 1)
		
		# Emit global signal for compatibility
		Global.placeable_item_placed.emit(current_placing_item)
		
		print("[PlaceableItemManager] Placed ", current_placing_item.name)
		current_placing_item = null
		_reopen_menu()
	else:
		print("[PlaceableItemManager] Error: Item does not have a 'place' method")

func cancel_placement():
	if current_placing_item != null:
		current_placing_item.queue_free()
		current_placing_item = null
		print("[PlaceableItemManager] Placement cancelled")
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

func get_all_placeable_items() -> Array[Node2D]:
	# Cleanup invalid references (queued for deletion)
	all_placeable_items = all_placeable_items.filter(func(f): return is_instance_valid(f))
	return all_placeable_items
