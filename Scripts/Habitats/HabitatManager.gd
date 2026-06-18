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
		return

	# Wait for physics frame so overlapping bodies and groups are updated
	await Global.get_tree().physics_frame
	if not is_instance_valid(placed_item): return

	# If we placed furniture, check if it's inside any HabitatZone
	if placed_item.is_in_group("furniture"):
		var all_zones = Global.current_world.get_tree().get_nodes_in_group("habitat_zones")
		for zone in all_zones:
			if zone is HabitatZone:
				zone._update_furniture_inside()
				zone.check_habitat_recipe()

func check_zone_for_habitat(zone: HabitatZone):
	print("[HabitatManager] Checking zone for habitat: ", zone.name)
	
	for recipe in habitat_recipes:
		var found_components = find_recipe_components_in_zone(recipe, zone)
		if found_components.size() > 0:
			print("[HabitatManager] SUCCESS: Habitat formed in zone!")
			var habitat = create_habitat(recipe, found_components, zone)
			zone.set_habitat(habitat)
			break

func find_recipe_components_in_zone(recipe: HabitatData, zone: HabitatZone) -> Array[Node2D]:
	var components_found: Array[Node2D] = []
	var recipe_counts = recipe.recipe.duplicate()
	
	print("[HabitatManager] Checking recipe '", recipe.habitat_name, "' in zone. Items in zone: ", zone.furniture_inside.size())
	
	for item in zone.furniture_inside:
		if not item.is_placed: 
			print("[HabitatManager]   - Item ", item.name, " is NOT placed yet.")
			continue
			
		var type: Types.FurnitureType = Types.FurnitureType.MISC
		if "furniture_data" in item and item.furniture_data:
			type = item.furniture_data.furniture_type
		
		var type_string = Types.furniture_to_string(type)
		print("[HabitatManager]   - Found item type: '", type_string, "' (", item.name, ")")
		
		if recipe_counts.has(type_string) and recipe_counts[type_string] > 0:
			# Check if this item is already part of another habitat
			if item.get_meta("habitat_parent", null) == null:
				components_found.append(item)
				recipe_counts[type_string] -= 1
				print("[HabitatManager]     Matches requirement! Remaining: ", recipe_counts[type_string], " for ", type_string)
	
	# Verify if all requirements are met
	for type in recipe_counts:
		if recipe_counts[type] > 0:
			return [] # Recipe incomplete
			
	return components_found

func find_recipe_components(recipe: HabitatData, center_item: Node2D) -> Array[Node2D]:
	# (Old proximity logic, keep for safety or remove if fully switching)
	# ... (existing code)
	return []

func create_habitat(recipe: HabitatData, components: Array[Node2D], zone: HabitatZone = null) -> Habitat:
	var habitat = habitat_scene.instantiate()
	habitat.name = recipe.habitat_name
	habitat.data = recipe
	habitat.components = components
	habitat.habitat_zone = zone
	
	# Calculate center position
	var avg_pos = Vector2.ZERO
	for c in components:
		avg_pos += c.global_position
	
	if zone:
		habitat.global_position = zone.global_position
	else:
		habitat.global_position = avg_pos / components.size()
	
	Global.current_world.add_child(habitat)
	
	for c in components:
		# Visual feedback and metadata to mark as used
		c.set_meta("habitat_parent", habitat)
		c.modulate = Color(0.8, 1.2, 0.8)
	
	all_habitats.append(habitat)
	habitat_created.emit(habitat)
	print("[HabitatManager] Created ", habitat.name, " with ", components.size(), " items.")
	return habitat

func cleanup_habitats():
	all_habitats = all_habitats.filter(func(h): return is_instance_valid(h))
