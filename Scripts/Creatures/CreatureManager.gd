extends Node

var all_creatures: Array[Creature] = []

@export var base_creature_scene: PackedScene = preload("res://Scenes/Creature.tscn")

## Spawns a creature for a specific habitat
func spawn_creature_for_habitat(habitat: Habitat) -> Creature:
	if not is_instance_valid(Global.current_world):
		print("[CreatureManager] Error: Global.current_world is not valid. Register it in Game.gd.")
		return null
		
	var creature: Creature
	
	if habitat.data.creature_data:
		# Dynamic spawning using single scene
		creature = base_creature_scene.instantiate()
		creature.data = habitat.data.creature_data
	elif habitat.data.creature_scene:
		# Legacy spawning using specific scenes
		creature = habitat.data.creature_scene.instantiate()
	else:
		print("[CreatureManager] Warning: No creature_data or creature_scene assigned to habitat '", habitat.name, "'.")
		return null
		
	# Position the creature near the habitat center
	var spawn_pos = habitat.global_position + Vector2(
		randf_range(-20, 20), 
		randf_range(-20, 20)
	)
	creature.global_position = spawn_pos
	
	# Set up relationships
	if "habitat" in creature:
		if habitat.habitat_zone:
			creature.habitat = habitat.habitat_zone
		else:
			creature.habitat = habitat
		
	# Add to world
	Global.current_world.add_child(creature)
	
	# Track the creature
	all_creatures.append(creature)
	
	# Inform the habitat (it might want to keep its own list too)
	if habitat.has_method("on_creature_spawned"):
		habitat.on_creature_spawned(creature)
	
	print("[CreatureManager] Spawned ", creature.name, " at ", spawn_pos)
	return creature

## Cleanup invalid creature references
func cleanup_creatures():
	all_creatures = all_creatures.filter(func(c): return is_instance_valid(c))

## Returns all creatures of a specific species
func get_creatures_by_species(species_name: String) -> Array[Creature]:
	cleanup_creatures()
	return all_creatures.filter(func(c): return c.data and c.data.species_name == species_name)

## Total population count
func get_total_population() -> int:
	cleanup_creatures()
	return all_creatures.size()
