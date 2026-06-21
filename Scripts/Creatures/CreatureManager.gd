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
		
	# Determine spawn position inside living area if it exists
	var spawn_pos = habitat.global_position
	var area = habitat.living_area if "living_area" in habitat else null
	if area and is_instance_valid(area) and area is LivingArea:
		spawn_pos = _find_random_empty_position_in_area(area)
	else:
		# Position the creature near the habitat center (fallback)
		spawn_pos = habitat.global_position + Vector2(
			randf_range(-20, 20), 
			randf_range(-20, 20)
		)
	creature.global_position = spawn_pos
	
	# Set up relationships
	if "habitat" in creature:
		if habitat.living_area:
			creature.habitat = habitat.living_area
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

func _find_random_empty_position_in_area(area: LivingArea) -> Vector2:
	cleanup_creatures()
	
	var shape_size = Vector2(256.0, 256.0)
	var zone_center = area.global_position + Vector2(64.0, 64.0)
	
	if area.collision and area.collision.shape is RectangleShape2D:
		shape_size = area.collision.shape.size
		zone_center = area.collision.global_position
		
	var half_size = shape_size / 2.0
	var min_x = zone_center.x - half_size.x
	var max_x = zone_center.x + half_size.x
	var min_y = zone_center.y - half_size.y
	var max_y = zone_center.y + half_size.y
	
	var valid_positions: Array[Vector2] = []
	
	# Check 16x16 cells
	var curr_x = min_x + 8.0
	while curr_x < max_x:
		var curr_y = min_y + 8.0
		while curr_y < max_y:
			var pos = Vector2(curr_x, curr_y)
			if _is_position_empty(pos, area):
				valid_positions.append(pos)
			curr_y += 16.0
		curr_x += 16.0
		
	if valid_positions.size() > 0:
		return valid_positions[randi() % valid_positions.size()]
		
	# Fallback if no empty positions are found
	return zone_center

func _is_position_empty(pos: Vector2, area: LivingArea) -> bool:
	var cell_rect = Rect2(pos.x - 8.0, pos.y - 8.0, 16.0, 16.0)
	
	# Check against placeable items in this area
	for f in area.placeable_items_inside:
		if is_instance_valid(f) and f.is_placed and "placeable_item_data" in f and f.placeable_item_data:
			var half_w = f.placeable_item_data.size.x * 8.0
			var half_h = f.placeable_item_data.size.y * 8.0
			var f_rect = Rect2(f.global_position.x - half_w, f.global_position.y - half_h, half_w * 2.0, half_h * 2.0)
			if f_rect.intersects(cell_rect):
				return false
				
	# Check against other creatures in the world
	for c in all_creatures:
		if is_instance_valid(c):
			if pos.distance_to(c.global_position) < 12.0:
				return false
				
	return true
