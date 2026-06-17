extends Node

# Signal emitted when any resource amount changes
signal inventory_updated
# Signal emitted for a specific resource change
signal resource_changed(type: String, new_amount: int)

@export var resource_definitions: Array[ResourceVisualData] = []

# Internal inventory state: { "Wood": 10, "Stone": 5, ... }
var inventory: Dictionary = {}

func _ready():
	_load_resource_definitions()
	_initialize_inventory()

## Automatically loads all .tres files from res://Ressources/
func _load_resource_definitions():
	var path = "res://Ressources/"
	if not DirAccess.dir_exists_absolute(path):
		print("ResourcesManager Error: Path ", path, " does not exist.")
		return

	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var res = load(path + file_name)
				if res is ResourceVisualData:
					resource_definitions.append(res)
			file_name = dir.get_next()
	print("ResourcesManager: Loaded ", resource_definitions.size(), " resource definitions.")

## Ensures all defined resources are present in the inventory dictionary
func _initialize_inventory():
	for res in resource_definitions:
		if res and res.type != "":
			if not inventory.has(res.type):
				inventory[res.type] = 0
	
	# Default fallback resources if not defined in files
	var defaults = ["Wood", "Stone", "Berry"]
	for d in defaults:
		if not inventory.has(d):
			inventory[d] = 0

## Returns the ResourceVisualData for a given resource type
func get_resource_data(type: String) -> ResourceVisualData:
	for res in resource_definitions:
		if res and res.type == type:
			return res
	return null

## Adds a specified amount of a resource
func add_resource(type: String, amount: int):
	if not inventory.has(type):
		inventory[type] = 0
	
	inventory[type] += amount
	print("ResourcesManager: Gained ", amount, " ", type, "! Total: ", inventory[type])
	resource_changed.emit(type, inventory[type])
	inventory_updated.emit()

## Spends a specified amount of a resource if available
func spend_resource(type: String, amount: int) -> bool:
	if can_afford(type, amount):
		inventory[type] -= amount
		print("ResourcesManager: Spent ", amount, " ", type, "! Remaining: ", inventory[type])
		resource_changed.emit(type, inventory[type])
		inventory_updated.emit()
		return true
	
	print("ResourcesManager: Not enough ", type, "!")
	return false

## Checks if the inventory has enough of a resource
func can_afford(type: String, amount: int) -> bool:
	return inventory.get(type, 0) >= amount

## Checks if the inventory has enough for multiple costs (Dictionary of type: amount)
func can_afford_multiple(costs: Dictionary) -> bool:
	for type in costs:
		if not can_afford(type, costs[type]):
			return false
	return true

## Spends multiple resources at once
func spend_multiple(costs: Dictionary) -> bool:
	if not can_afford_multiple(costs):
		return false
	
	for type in costs:
		inventory[type] -= costs[type]
		resource_changed.emit(type, inventory[type])
	
	inventory_updated.emit()
	return true

## Returns the current amount of a resource
func get_amount(type: String) -> int:
	return inventory.get(type, 0)

## Returns the entire inventory dictionary
func get_all_resources() -> Dictionary:
	return inventory.duplicate()
