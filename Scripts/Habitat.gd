extends Node2D
class_name Habitat

var data: HabitatData
var components: Array[Node2D] = [] # Furniture pieces making this habitat
var spawned_creatures: Array[Creature] = []
var creature_manager: CreatureManager

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
	if creature_manager:
		creature_manager.spawn_creature_for_habitat(self)
	else:
		print("[Habitat] Warning: No creature_manager assigned to habitat '", name, "'.")

func on_creature_spawned(creature: Creature):
	spawn_creatures_clean_up() # Remove dead ones from list
	spawned_creatures.append(creature)

func spawn_creatures_clean_up():
	spawned_creatures = spawned_creatures.filter(func(c): return is_instance_valid(c))
