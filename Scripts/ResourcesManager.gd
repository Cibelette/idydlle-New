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

## Automatically loads all .tres files from res://Ressources/ and its subfolders
func _load_resource_definitions():
	var path = "res://Ressources/"
	var files = _get_files_recursive(path, ".tres")

	for file_path in files:
		var res = load(file_path)
		if res is ResourceVisualData:
			resource_definitions.append(res)

	print("ResourcesManager: Loaded ", resource_definitions.size(), " resource definitions recursively.")

## Helper function to find all files with a specific extension in a directory and its subdirectories
func _get_files_recursive(path: String, extension: String) -> Array[String]:
	var files: Array[String] = []
	if not path.ends_with("/"):
		path += "/"

	if not DirAccess.dir_exists_absolute(path):
		return files

	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				files.append_array(_get_files_recursive(path + file_name + "/", extension))
			else:
				if file_name.ends_with(extension):
					files.append(path + file_name)
			file_name = dir.get_next()
	return files


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
