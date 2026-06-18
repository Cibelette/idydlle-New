@tool
extends StaticBody2D

@export var is_placed: bool = false
@export var furniture_data: FurnitureData

@onready var sprite: Sprite2D = $Sprite2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready():
	_apply_data()
	
	if Engine.is_editor_hint():
		set_notify_transform(true)
		return

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
			animated_sprite.visible = true
			animated_sprite.play("default")
			sprite.visible = false
		else:
			animated_sprite.visible = false
			sprite.visible = true
			sprite.texture = furniture_data.texture
			
	if collision and collision.shape is RectangleShape2D:
		collision.shape.size = furniture_data.collision_size

func _notification(what):
	if Engine.is_editor_hint():
		if what == NOTIFICATION_TRANSFORM_CHANGED:
			# Only snap if we are not being actively dragged (optional refinement)
			# For simplicity, we snap whenever transform changes in editor
			global_position = (global_position / 16.0).floor() * 16.0 + Vector2(8, 8)

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
	var habitat = get_meta("habitat_parent", null)
	if habitat and is_instance_valid(habitat):
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
	
	var habitat = get_meta("habitat_parent", null)
	if habitat and is_instance_valid(habitat):
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
