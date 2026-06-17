extends Node2D
class_name Habitat

var data: HabitatData
var components: Array[Node2D] = [] # Furniture pieces making this habitat
var spawned_creatures: Array[Creature] = []

@onready var spawn_timer: Timer = Timer.new()

func _ready():
	add_child(spawn_timer)
	spawn_timer.wait_time = data.spawn_cooldown
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()
	
	print("[Habitat] Formed: ", data.habitat_name, " at ", global_position)

func _on_spawn_timer_timeout():
	if spawned_creatures.size() < data.max_creatures:
		spawn_creature()

func spawn_creature():
	if not data or not data.creature_scene:
		print("[Habitat] Warning: No creature_scene assigned to habitat '", name, "'. Spawning cancelled.")
		return
		
	var creature = data.creature_scene.instantiate()
	creature.global_position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
	
	# Pass the habitat reference to the creature
	if "habitat" in creature:
		creature.habitat = self
		
	get_parent().add_child(creature)
	spawn_creatures_clean_up() # Remove dead ones from list
	spawned_creatures.append(creature)
	print("[Habitat] Spawned ", creature.name)

func spawn_creatures_clean_up():
	spawned_creatures = spawned_creatures.filter(func(c): return is_instance_valid(c))
