extends Node

signal habitat_created(habitat: Habitat)

# List of all possible habitat recipes
@export var habitat_recipes: Array[HabitatData] = []

# Track all active habitats globally
var all_habitats: Array[Habitat] = []

var habitat_scene = preload("res://Scenes/Habitat.tscn")

## Checks if a new habitat can be formed around the item just placed
func check_for_new_habitat(placed_item: Node2D):
	if not is_instance_valid(Global.current_world):
		print("[HabitatManager] Error: Global.current_world is not valid. Register it in Game.gd.")
		return

	print("[HabitatManager] Checking item: ", placed_item.name)
	if not "furniture_data" in placed_item or not placed_item.furniture_data:
		print("[HabitatManager] Aborting: No furniture_data found")
		return
	
	print("[HabitatManager] Item type: ", placed_item.furniture_data.furniture_type)
	
	for recipe in habitat_recipes:
		print("[HabitatManager] Testing recipe: ", recipe.habitat_name)
		var found_components = find_recipe_components(recipe, placed_item)
		if found_components.size() > 0:
			print("[HabitatManager] SUCCESS: Habitat formed!")
			create_habitat(recipe, found_components)
			break

func find_recipe_components(recipe: HabitatData, center_item: Node2D) -> Array[Node2D]:
	# Get all furniture in the world (you might want to use groups for optimization)
	var all_furniture = Global.current_world.get_tree().get_nodes_in_group("furniture")
	
	var components_found: Array[Node2D] = []
	var recipe_counts = recipe.recipe.duplicate()
	
	# Start with the item just placed
	var center_type = ""
	if "furniture_data" in center_item and center_item.furniture_data:
		center_type = center_item.furniture_data.furniture_type
	
	# Basic proximity check
	for item in all_furniture:
		if not item.is_placed: continue
		if item.global_position.distance_to(center_item.global_position) > recipe.detection_radius:
			continue
			
		var type = ""
		if "furniture_data" in item and item.furniture_data:
			type = item.furniture_data.furniture_type
		
		if recipe_counts.has(type) and recipe_counts[type] > 0:
			# Check if this item is already part of another habitat
			if item.get_meta("habitat_parent", null) == null:
				components_found.append(item)
				recipe_counts[type] -= 1
	
	# Verify if all requirements are met (all counts should be 0)
	for type in recipe_counts:
		if recipe_counts[type] > 0:
			return [] # Recipe incomplete
			
	return components_found

func create_habitat(recipe: HabitatData, components: Array[Node2D]):
	var habitat = habitat_scene.instantiate()
	habitat.name = recipe.habitat_name
	habitat.data = recipe
	habitat.components = components
	
	# Calculate center position before reparenting
	var avg_pos = Vector2.ZERO
	for c in components:
		avg_pos += c.global_position
	
	habitat.global_position = avg_pos / components.size()
	
	# Add the habitat to the world first
	Global.current_world.add_child(habitat)
	
	# Now reparent each component to be a child of the habitat
	for c in components:
		c.reparent(habitat) # Keeps global position by default in Godot 4
		c.set_meta("habitat_parent", habitat)
		c.modulate = Color(0.8, 1.2, 0.8) # Visual feedback
	
	all_habitats.append(habitat)
	habitat_created.emit(habitat)
	print("[HabitatManager] Created ", habitat.name, " with ", components.size(), " items.")

func cleanup_habitats():
	all_habitats = all_habitats.filter(func(h): return is_instance_valid(h))
