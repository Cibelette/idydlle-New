extends Node2D
class_name Habitat

var data: HabitatData
var components: Array[Node2D] = [] # PlaceableItem pieces making this habitat
var spawned_creatures: Array[Creature] = []
var living_area: Node2D = null

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
	CreatureManager.spawn_creature_for_habitat(self)

func on_creature_spawned(creature: Creature):
	spawn_creatures_clean_up() # Remove dead ones from list
	spawned_creatures.append(creature)

func spawn_creatures_clean_up():
	spawned_creatures = spawned_creatures.filter(func(c): return is_instance_valid(c))

func _process(_delta):
	var valid_components = components.filter(func(c): return is_instance_valid(c) and c.is_placed)
	if valid_components.size() < components.size():
		dissolve()

func dissolve():
	print("[Habitat] Dissolving: ", data.habitat_name)
	
	for c in components:
		if is_instance_valid(c):
			c.set_meta("habitat_parent", null)
			c.modulate = Color(1.0, 1.0, 1.0)
			
	for c in spawned_creatures:
		if is_instance_valid(c):
			c.queue_free()
			
	if living_area and is_instance_valid(living_area):
		living_area.set_habitat(null)
		
	if HabitatManager.all_habitats.has(self):
		HabitatManager.all_habitats.erase(self)
		
	queue_free()
