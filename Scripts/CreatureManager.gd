extends Node

# Reference to the world node where creatures should be added
var world_node: Node2D
var all_creatures: Array[Creature] = []

## Spawns a creature for a specific habitat
func spawn_creature_for_habitat(habitat: Habitat) -> Creature:
	if not is_instance_valid(world_node):
		print("[CreatureManager] Error: world_node is not valid. Register it in Game.gd.")
		return null
		
	if not habitat.data or not habitat.data.creature_scene:
		print("[CreatureManager] Warning: No creature_scene assigned to habitat '", habitat.name, "'.")
		return null
		
	var creature = habitat.data.creature_scene.instantiate()
	
	# Position the creature near the habitat center
	var spawn_pos = habitat.global_position + Vector2(
		randf_range(-20, 20), 
		randf_range(-20, 20)
	)
	creature.global_position = spawn_pos
	
	# Set up relationships
	if "habitat" in creature:
		creature.habitat = habitat
		
	# Add to world
	world_node.add_child(creature)
	
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
