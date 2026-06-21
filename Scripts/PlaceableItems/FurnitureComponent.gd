extends Node
class_name FurnitureComponent

@onready var parent: PlaceableItem = get_parent()

var inventory: Dictionary = {}
var bubble_indicator: BubbleIndicator = null

func _ready():
	_init_bubble()

func _init_bubble():
	var data = parent.placeable_item_data as FurnitureData
	if not data or data.function != Types.FurnitureFunction.STORAGE: return
	if not data.bubble_texture: return
	
	bubble_indicator = BubbleIndicator.new()
	parent.add_child(bubble_indicator)
	bubble_indicator.setup(
		data.bubble_texture,
		data.bubble_offset,
		data.scale
	)
	
	_update_bubble()

func get_inventory() -> Dictionary:
	if parent.living_area and is_instance_valid(parent.living_area):
		return parent.living_area.inventory
	return inventory

func _update_bubble():
	if not bubble_indicator or not is_instance_valid(bubble_indicator): return
	
	var inv = get_inventory()
	if inv.is_empty():
		bubble_indicator.hide_bubble()
	else:
		var resource_type = inv.keys()[0]
		var res_data = ResourcesManager.get_resource_data(resource_type)
		if res_data and res_data.sprite:
			bubble_indicator.show_icon(res_data.sprite)
		else:
			bubble_indicator.hide_bubble()

func store_resource(type: Types.ResourceType, amount: int):
	var inv = get_inventory()
	if inv.has(type):
		inv[type] += amount
	else:
		inv[type] = amount
	
	if parent.living_area and is_instance_valid(parent.living_area):
		parent.living_area.update_all_chests_bubbles()
	else:
		_update_bubble()

func collect_inventory():
	var inv = get_inventory()
	if inv.is_empty():
		print("[Storage] Chest is empty.")
		return
		
	print("[Storage] Collecting from Chest:")
	
	var popup_scene = parent.resource_popup_scene
	var idx = 0
	var total_types = inv.size()
	
	var inv_dup = inv.duplicate()
	for type in inv_dup:
		var amount = inv_dup[type]
		ResourcesManager.add_resource(type, amount)
		print("  - Added ", amount, " ", Types.resource_to_string(type), " to global storage.")
		
		if popup_scene:
			var popup = popup_scene.instantiate()
			var offset_x = (idx - (total_types - 1) / 2.0) * 24.0
			var spawn_pos = parent.global_position + Vector2(offset_x, -20.0)
			popup.global_position = spawn_pos
			
			parent.get_parent().add_child(popup)
			popup.setup(type, amount)
			
			var burst = SparkleBurst.new()
			burst.global_position = spawn_pos + Vector2(0, 10)
			parent.get_parent().add_child(burst)
			burst.setup(type)
		idx += 1
		
	inv.clear()
	
	if parent.living_area and is_instance_valid(parent.living_area):
		parent.living_area.update_all_chests_bubbles()
	else:
		_update_bubble()
	
	var tween = parent.create_tween()
	tween.tween_property(parent, "modulate", Color(1.5, 1.5, 1.5), 0.15)
	tween.tween_property(parent, "modulate", Color(1.0, 1.0, 1.0), 0.15)
