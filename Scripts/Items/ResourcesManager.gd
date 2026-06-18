extends Node

# Signal emitted when any resource amount changes
signal inventory_updated
# Signal emitted for a specific resource change
signal resource_changed(type: Types.ResourceType, new_amount: int)

@export var resource_definitions: Array[ResourceVisualData] = []

# Internal inventory state: { Types.ResourceType.WOOD: 10, Types.ResourceType.STONE: 5, ... }
var inventory: Dictionary = {}

func _ready():
	_load_resource_definitions()
	_initialize_inventory()

## Automatically loads all .tres files from res://Ressources/ and its subfolders
func _load_resource_definitions():
	var path = "res://Ressources/"
	var files = Utils.get_files_recursive(path, ".tres")

	for file_path in files:
		var res = load(file_path)
		if res is ResourceVisualData:
			resource_definitions.append(res)

	print("ResourcesManager: Loaded ", resource_definitions.size(), " resource definitions recursively.")

## Ensures all defined resources are present in the inventory dictionary
func _initialize_inventory():
	for res in resource_definitions:
		if res and res.type != Types.ResourceType.NONE:
			if not inventory.has(res.type):
				inventory[res.type] = 0
	
	# Default fallback resources if not defined in files
	var defaults = [Types.ResourceType.WOOD, Types.ResourceType.STONE, Types.ResourceType.BERRY]
	for d in defaults:
		if not inventory.has(d):
			inventory[d] = 0

## Returns the ResourceVisualData for a given resource type
func get_resource_data(type_in) -> ResourceVisualData:
	var type: Types.ResourceType = type_in if type_in is Types.ResourceType else Types.string_to_resource(str(type_in))
	for res in resource_definitions:
		if res and res.type == type:
			return res
	return null

## Adds a specified amount of a resource
func add_resource(type_in, amount: int):
	var type: Types.ResourceType = type_in if type_in is Types.ResourceType else Types.string_to_resource(str(type_in))
	if type == Types.ResourceType.NONE:
		print("Warning: Attempted to add NONE/invalid resource type.")
		return
		
	if not inventory.has(type):
		inventory[type] = 0
	
	inventory[type] += amount
	print("ResourcesManager: Gained ", amount, " ", Types.resource_to_string(type), "! Total: ", inventory[type])
	resource_changed.emit(type, inventory[type])
	inventory_updated.emit()

## Spends a specified amount of a resource if available
func spend_resource(type_in, amount: int) -> bool:
	var type: Types.ResourceType = type_in if type_in is Types.ResourceType else Types.string_to_resource(str(type_in))
	if type == Types.ResourceType.NONE:
		return false
		
	if can_afford(type, amount):
		inventory[type] -= amount
		print("ResourcesManager: Spent ", amount, " ", Types.resource_to_string(type), "! Remaining: ", inventory[type])
		resource_changed.emit(type, inventory[type])
		inventory_updated.emit()
		return true
	
	print("ResourcesManager: Not enough ", Types.resource_to_string(type), "!")
	return false

## Checks if the inventory has enough of a resource
func can_afford(type_in, amount: int) -> bool:
	var type: Types.ResourceType = type_in if type_in is Types.ResourceType else Types.string_to_resource(str(type_in))
	return inventory.get(type, 0) >= amount

## Checks if the inventory has enough for multiple costs (Dictionary or Array[CostItem])
func can_afford_multiple(costs) -> bool:
	if costs is Dictionary:
		for key in costs:
			var type: Types.ResourceType = key if key is Types.ResourceType else Types.string_to_resource(str(key))
			if not can_afford(type, costs[key]):
				return false
	elif costs is Array:
		for cost_item in costs:
			if cost_item and not can_afford(cost_item.resource, cost_item.amount):
				return false
	return true

## Spends multiple resources at once
func spend_multiple(costs) -> bool:
	if not can_afford_multiple(costs):
		return false
	
	if costs is Dictionary:
		for key in costs:
			var type: Types.ResourceType = key if key is Types.ResourceType else Types.string_to_resource(str(key))
			inventory[type] -= costs[key]
			resource_changed.emit(type, inventory[type])
	elif costs is Array:
		for cost_item in costs:
			if cost_item:
				inventory[cost_item.resource] -= cost_item.amount
				resource_changed.emit(cost_item.resource, inventory[cost_item.resource])
	
	inventory_updated.emit()
	return true

## Returns the current amount of a resource
func get_amount(type_in) -> int:
	var type: Types.ResourceType = type_in if type_in is Types.ResourceType else Types.string_to_resource(str(type_in))
	return inventory.get(type, 0)

## Returns the entire inventory dictionary
func get_all_resources() -> Dictionary:
	return inventory.duplicate()
