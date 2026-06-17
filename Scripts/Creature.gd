extends CharacterBody2D

class_name Creature

@export var data: CreatureData
@export var habitat: Node2D
@export var wander_radius: float = 100.0
@export var movement_speed: float = 50.0

var target_position: Vector2
var is_moving: bool = false

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var production_timer: Timer = $Timer # On réutilise le timer existant dans la scène
@onready var happiness_label: Label = get_node_or_null("Happiness/Label")
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _process(delta):
	if is_moving:
		velocity = (target_position - global_position).normalized() * movement_speed
		move_and_slide()
		
		if global_position.distance_to(target_position) < 5.0:
			is_moving = false
	elif randf() < 0.01: # Random chance to wander
		_wander()

func _wander():
	var center = global_position
	if habitat:
		center = habitat.global_position
	
	var offset = Vector2(randf_range(-wander_radius, wander_radius), randf_range(-wander_radius, wander_radius))
	target_position = center + offset
	is_moving = true

func _ready():
	_apply_data()
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	if habitat:
		print("[Creature] Habitat trouvé : ", habitat.global_position)

func _apply_data():
	if not data: return
	
	# Visuals
	if sprite and data.sprite_frames:
		sprite.sprite_frames = data.sprite_frames
		sprite.play("default") # Ensure it starts playing
		
	# Update scale
	scale = Vector2(data.scale, data.scale)
	
	# Configuration de la production basée sur les données de la ressource
	if production_timer:
		production_timer.wait_time = data.produce_time
		production_timer.start()
	
	update_happiness_display()

func update_happiness_display():
	if data:
		var text = "Happiness: " + str(data.hapiness)
		if happiness_label:
			happiness_label.text = text
		else:
			# Check for the structure in Creature.tscn
			var alt_label = get_node_or_null("Happiness/Label")
			if alt_label:
				alt_label.text = text

func _on_timer_timeout():
	if data:
		# The timer now only handles sounds/flavor text
		print(data.species_name, " dit : ", data.sound_text)

func produce_from_source(source: Node2D):
	if not data or not source: return
	
	# Amount = Creature Amount * Furniture Amount
	# We assume the source is a Furniture with furniture_data
	var f_amount = 0
	if "furniture_data" in source and source.furniture_data:
		f_amount = source.furniture_data.produce_amount
		
	var total_amount = data.produce_amount * f_amount
	
	if total_amount > 0:
		ResourcesManager.add_resource(data.resource_type, total_amount)
		print("[Production] ", data.species_name, " harvested ", total_amount, " ", data.resource_type, " from ", source.name)

## Allows you to inject custom data at runtime (e.g. for evolutions)
func set_creature_data(new_data: CreatureData):
	data = new_data
	_apply_data()
		


func setup_creature():
	# Cette fonction peut être appelée pour initialiser spécifiquement si besoin
	pass
	
