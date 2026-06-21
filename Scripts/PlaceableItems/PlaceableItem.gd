@tool
extends StaticBody2D
class_name PlaceableItem

@export var is_placed: bool = false
@export var placeable_item_data: PlaceableItemData
@export var resource_popup_scene: PackedScene = preload("res://Scenes/resource_popup.tscn")

@onready var sprite: Sprite2D = $Sprite2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

var living_area: LivingArea = null

# Component references
var furniture_component: FurnitureComponent = null
var natural_resource_component: NaturalResourceComponent = null

func _ready():
	input_pickable = true
	# Force connection in case Godot's implicit routing fails
	if not input_event.is_connected(_input_event):
		input_event.connect(_input_event)
		
	_apply_data()
	_setup_components()
	
	if Engine.is_editor_hint():
		set_notify_transform(true)
		return

	# Connect hover events for playing animation
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)

	if is_placed:
		place()
	else:
		if collision:
			collision.disabled = true
		modulate.a = 0.5

func _setup_components():
	if Engine.is_editor_hint(): return
	if not placeable_item_data: return
	
	if placeable_item_data is NaturalResourceData:
		natural_resource_component = NaturalResourceComponent.new()
		add_child(natural_resource_component)
	elif placeable_item_data is FurnitureData:
		furniture_component = FurnitureComponent.new()
		add_child(furniture_component)

func _apply_data():
	if not placeable_item_data: return
	
	if animated_sprite and sprite:
		animated_sprite.scale = Vector2(placeable_item_data.scale, placeable_item_data.scale)
		sprite.scale = Vector2(placeable_item_data.scale, placeable_item_data.scale)
		
		if placeable_item_data.sprite_frames:
			animated_sprite.sprite_frames = placeable_item_data.sprite_frames
			if placeable_item_data.texture:
				animated_sprite.visible = false
				animated_sprite.stop()
				sprite.visible = true
				sprite.texture = placeable_item_data.texture
			else:
				animated_sprite.visible = true
				animated_sprite.play("default")
				sprite.visible = false
		else:
			animated_sprite.visible = false
			sprite.visible = true
			sprite.texture = placeable_item_data.texture

func _on_mouse_entered():
	if not is_placed: return
	if not placeable_item_data: return
	
	if animated_sprite and sprite and placeable_item_data.sprite_frames and placeable_item_data.texture:
		sprite.visible = false
		animated_sprite.visible = true
		animated_sprite.play("default")

func _on_mouse_exited():
	if not is_placed: return
	if not placeable_item_data: return
	
	if animated_sprite and sprite and placeable_item_data.sprite_frames and placeable_item_data.texture:
		animated_sprite.stop()
		animated_sprite.visible = false
		sprite.visible = true

# Unified interfaces delegated to components
func get_inventory() -> Dictionary:
	if furniture_component:
		return furniture_component.get_inventory()
	return {}

func _update_bubble():
	if furniture_component:
		furniture_component._update_bubble()

func store_resource(type: Types.ResourceType, amount: int):
	if furniture_component:
		furniture_component.store_resource(type, amount)

func _notification(what):
	if Engine.is_editor_hint():
		if what == NOTIFICATION_TRANSFORM_CHANGED:
			var size_px = Vector2(16, 16)
			if placeable_item_data:
				size_px = Vector2(placeable_item_data.size) * Global.grid_size
			
			var new_pos = Global.snap_to_grid(global_position, size_px)
			if global_position != new_pos:
				global_position = new_pos

func place():
	is_placed = true
	add_to_group("placeable_items")
	collision.disabled = false
	modulate.a = 1.0
	z_index = int(global_position.y) 
	
	GridManager.register_item(self)
	
	var obstacle = get_node_or_null("NavigationObstacle2D")
	if obstacle:
		obstacle.avoidance_enabled = true
		
	# Trigger production start on component if it exists
	if natural_resource_component:
		natural_resource_component.start_production()

func _get_current_living_area() -> LivingArea:
	var zones = get_tree().get_nodes_in_group("living_areas")
	for zone in zones:
		if zone is LivingArea and zone.placeable_items_inside.has(self):
			return zone
	return null

func _input_event(viewport: Node, event: InputEvent, shape_idx: int):
	if is_placed and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if furniture_component and placeable_item_data.function == Types.FurnitureFunction.STORAGE:
				furniture_component.collect_inventory()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			pickup()

func pickup():
	if not is_placed: return
	
	if furniture_component and placeable_item_data.function == Types.FurnitureFunction.STORAGE:
		furniture_component.collect_inventory()
		
	GridManager.deregister_item(self)
		
	if living_area and is_instance_valid(living_area):
		if living_area.placeable_items_inside.has(self):
			living_area.placeable_items_inside.erase(self)
		living_area.update_all_chests_bubbles()
		living_area.check_habitat_recipe()
		
	remove_from_group("placeable_items")
	if PlaceableItemManager.all_placeable_items.has(self):
		PlaceableItemManager.all_placeable_items.erase(self)
		
	if placeable_item_data:
		ResourcesManager.add_placeable_item(placeable_item_data, 1)
		
	print("[PlaceableItem] Picked up ", name, " into inventory.")
	queue_free()

func _exit_tree():
	if Engine.is_editor_hint(): return
	GridManager.deregister_item(self)
