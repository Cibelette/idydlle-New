extends CharacterBody2D

class_name Creature

@export var data: CreatureData
@export var habitat: Node2D
@onready var production_timer: Timer = $Timer # On réutilise le timer existant dans la scène
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

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
	

func produce_from_source(source: Node2D):
	if not data or not source: return
	
	# Verify we are in a LivingArea
	if not habitat or not habitat is LivingArea:
		print("[Production] ", data.species_name, " aborted harvest: Not in a valid LivingArea.")
		return
		
	# Find if there is at least one Chest in the LivingArea
	var has_chest = false
	for item in habitat.furniture_inside:
		if is_instance_valid(item) and "furniture_data" in item and item.furniture_data:
			if item.furniture_data.furniture_type == Types.FurnitureType.STORAGE:
				has_chest = true
				break
				
	if not has_chest:
		print("[Production] ", data.species_name, " aborted harvest: No Chest found in habitat to store resources.")
		return
	
	# Amount = Creature Amount * Furniture Amount
	# We assume the source is a Furniture with furniture_data
	var f_amount = 0
	if "furniture_data" in source and source.furniture_data:
		f_amount = source.furniture_data.produce_amount
		
	var total_amount = data.produce_amount * f_amount
	
	if total_amount > 0:
		# Store in the LivingArea inventory instead of a specific chest
		habitat.store_resource(data.resource_type, total_amount)
		print("[Production] ", data.species_name, " deposited ", total_amount, " ", Types.resource_to_string(data.resource_type), " into LivingArea inventory.")

## Allows you to inject custom data at runtime (e.g. for evolutions)
func set_creature_data(new_data: CreatureData):
	data = new_data
	_apply_data()
		


func setup_creature():
	# Cette fonction peut être appelée pour initialiser spécifiquement si besoin
	pass
	
