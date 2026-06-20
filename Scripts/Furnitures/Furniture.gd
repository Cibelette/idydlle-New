@tool
extends StaticBody2D

@export var is_placed: bool = false
@export var furniture_data: FurnitureData
@export var resource_popup_scene: PackedScene = preload("res://Scenes/resource_popup.tscn")

@onready var sprite: Sprite2D = $Sprite2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

var inventory: Dictionary = {}
var living_area: LivingArea = null

var bubble_indicator: BubbleIndicator = null

func _ready():
	input_pickable = true
	# Force connection in case Godot's implicit routing fails
	if not input_event.is_connected(_input_event):
		input_event.connect(_input_event)
		
	_apply_data()
	_init_bubble()
	
	if Engine.is_editor_hint():
		set_notify_transform(true)
		return

	# Connect hover events for playing animation
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)

	if is_placed:
		# If checked in Inspector, finalize immediately
		place()
	else:
		# Initially, collision is disabled while we are placing it
		if collision:
			collision.disabled = true
		# Give it some transparency to show it's a "ghost"
		modulate.a = 0.5

func _apply_data():
	if not furniture_data: return
	
	if animated_sprite and sprite:
		# Apply scale to the visual representation
		animated_sprite.scale = Vector2(furniture_data.scale, furniture_data.scale)
		sprite.scale = Vector2(furniture_data.scale, furniture_data.scale)
		
		if furniture_data.sprite_frames:
			animated_sprite.sprite_frames = furniture_data.sprite_frames
			if furniture_data.texture:
				# Default to static texture if both are present
				animated_sprite.visible = false
				animated_sprite.stop()
				sprite.visible = true
				sprite.texture = furniture_data.texture
			else:
				# Only sprite frames available
				animated_sprite.visible = true
				animated_sprite.play("default")
				sprite.visible = false
		else:
			animated_sprite.visible = false
			sprite.visible = true
			sprite.texture = furniture_data.texture
			
	# Note: Collision size is now determined by the scene (1x1, 2x1, etc.)

func _on_mouse_entered():
	if not is_placed: return
	if not furniture_data: return
	
	if animated_sprite and sprite and furniture_data.sprite_frames and furniture_data.texture:
		sprite.visible = false
		animated_sprite.visible = true
		animated_sprite.play("default")

func _on_mouse_exited():
	if not is_placed: return
	if not furniture_data: return
	
	if animated_sprite and sprite and furniture_data.sprite_frames and furniture_data.texture:
		animated_sprite.stop()
		animated_sprite.visible = false
		sprite.visible = true

func _init_bubble():
	if Engine.is_editor_hint(): return
	if not furniture_data or furniture_data.furniture_type != Types.FurnitureType.STORAGE: return
	if not furniture_data.bubble_texture: return
	
	bubble_indicator = BubbleIndicator.new()
	add_child(bubble_indicator)
	bubble_indicator.setup(
		furniture_data.bubble_texture,
		furniture_data.bubble_offset,
		furniture_data.scale
	)
	
	_update_bubble()

func get_inventory() -> Dictionary:
	if living_area and is_instance_valid(living_area):
		return living_area.inventory
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


func _notification(what):
	if Engine.is_editor_hint():
		if what == NOTIFICATION_TRANSFORM_CHANGED:
			var size_px = Vector2(16, 16)
			if furniture_data:
				size_px = Vector2(furniture_data.size) * Global.grid_size
			
			var new_pos = Global.snap_to_grid(global_position, size_px)
			if global_position != new_pos:
				global_position = new_pos

func place():
	is_placed = true
	add_to_group("furniture")
	collision.disabled = false
	modulate.a = 1.0
	# Set the Z index or layer if necessary to ensure it's behind/in front of things
	z_index = int(global_position.y) 
	
	# Update navigation obstacle if it exists
	var obstacle = get_node_or_null("NavigationObstacle2D")
	if obstacle:
		obstacle.avoidance_enabled = true
		
	# Start production if configured
	if furniture_data and furniture_data.produce_time > 0:
		start_production()

func start_production():
	var timer = Timer.new()
	timer.name = "ProductionTimer"
	add_child(timer)
	timer.timeout.connect(_on_production_timeout)
	# Initial interval setup
	timer.wait_time = _calculate_production_interval()
	timer.start()

func _calculate_production_interval() -> float:
	if not furniture_data: return 1.0
	
	var multiplier = 1.0
	var zone = _get_current_living_area()
	
	if zone and is_instance_valid(zone.active_habitat):
		var habitat = zone.active_habitat
		if habitat.has_method("spawn_creatures_clean_up"):
			habitat.spawn_creatures_clean_up()
			
		for creature in habitat.spawned_creatures:
			if is_instance_valid(creature) and creature.data and creature.data.resource_type == furniture_data.resource_type:
				# Use the creature's produce_time as the multiplier
				multiplier = creature.data.produce_time
				break
				
	return furniture_data.produce_time * multiplier

func _on_production_timeout():
	if not furniture_data: return
	
	var zone = _get_current_living_area()
	if zone and is_instance_valid(zone.active_habitat):
		# Check if the living area contains at least one chest
		var has_chest = false
		for item in zone.furniture_inside:
			if is_instance_valid(item) and "furniture_data" in item and item.furniture_data:
				if item.furniture_data.furniture_type == Types.FurnitureType.STORAGE:
					has_chest = true
					break
					
		if not has_chest:
			# Do not trigger production if there's no chest in the LivingArea
			return
			
		var habitat = zone.active_habitat
		var matched_any = false
		for creature in habitat.spawned_creatures:
			if is_instance_valid(creature) and creature.data and creature.data.resource_type == furniture_data.resource_type:
				if creature.has_method("produce_from_source"):
					creature.produce_from_source(self)
					matched_any = true
		
		# Update the timer interval for the next cycle based on current creatures
		var timer = $ProductionTimer
		if timer:
			timer.wait_time = _calculate_production_interval()
	else:
		# If no habitat, reset to base time or stay idle
		var timer = $ProductionTimer
		if timer:
			timer.wait_time = furniture_data.produce_time if furniture_data.produce_time > 0 else 1.0

func _get_current_living_area() -> LivingArea:
	var zones = get_tree().get_nodes_in_group("living_areas")
	for zone in zones:
		if zone is LivingArea and zone.furniture_inside.has(self):
			return zone
	return null

func _input_event(viewport: Node, event: InputEvent, shape_idx: int):
	if is_placed and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if furniture_data and furniture_data.furniture_type == Types.FurnitureType.STORAGE:
				collect_inventory()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			pickup()

func pickup():
	if not is_placed: return
	
	# If it's a storage, collect its contents first
	if furniture_data and furniture_data.furniture_type == Types.FurnitureType.STORAGE:
		collect_inventory()
		
	# Remove from living area if inside one
	if living_area and is_instance_valid(living_area):
		if living_area.furniture_inside.has(self):
			living_area.furniture_inside.erase(self)
		living_area.update_all_chests_bubbles()
		living_area.check_habitat_recipe()
		
	# Remove from group and all_furniture
	remove_from_group("furniture")
	if FurnitureManager.all_furniture.has(self):
		FurnitureManager.all_furniture.erase(self)
		
	# Add back to player inventory
	if furniture_data:
		ResourcesManager.add_furniture(furniture_data, 1)
		
	print("[Furniture] Picked up ", name, " into inventory.")
	queue_free()

func store_resource(type: Types.ResourceType, amount: int):
	var inv = get_inventory()
	if inv.has(type):
		inv[type] += amount
	else:
		inv[type] = amount
	
	if living_area and is_instance_valid(living_area):
		living_area.update_all_chests_bubbles()
	else:
		_update_bubble()

func collect_inventory():
	var inv = get_inventory()
	if inv.is_empty():
		print("[Storage] Chest is empty.")
		return
		
	print("[Storage] Collecting from Chest:")
	
	var popup_scene = resource_popup_scene
	var idx = 0
	var total_types = inv.size()
	
	var inv_dup = inv.duplicate()
	for type in inv_dup:
		var amount = inv_dup[type]
		ResourcesManager.add_resource(type, amount)
		print("  - Added ", amount, " ", Types.resource_to_string(type), " to global storage.")
		
		if popup_scene:
			var popup = popup_scene.instantiate()
			# Stagger popups horizontally if there are multiple types
			var offset_x = (idx - (total_types - 1) / 2.0) * 24.0
			var spawn_pos = global_position + Vector2(offset_x, -20.0)
			popup.global_position = spawn_pos
			
			get_parent().add_child(popup)
			popup.setup(type, amount)
			
			# Spawn themed sparkle burst
			var burst = SparkleBurst.new()
			burst.global_position = spawn_pos + Vector2(0, 10) # Positioned slightly below the text
			get_parent().add_child(burst)
			burst.setup(type)
		idx += 1
		
	inv.clear()
	
	if living_area and is_instance_valid(living_area):
		living_area.update_all_chests_bubbles()
	else:
		_update_bubble()
	
	# Visual feedback for collection
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.5, 1.5, 1.5), 0.15)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0), 0.15)
