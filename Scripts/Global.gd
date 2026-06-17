@tool
extends Node

signal ressource_inventory_updated
signal furniture_placed(item: Node2D)

@export var resource_definitions: Array[ResourceVisualData] = []

func _ready():
	_load_resource_definitions()

func _load_resource_definitions():
	var path = "res://Ressources/"
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
	print("Loaded ", resource_definitions.size(), " resource definitions.")

# Helper to quickly find data
func get_resource_data(type: String) -> ResourceVisualData:
	for res in resource_definitions:
		if res and res.type == type:
			return res
	return null

# A Dictionary is perfect for keeping track of multiple resource types
var ressource_inventory = {
	"Wood": 0,
	"Berry": 0,
	"Stone": 0
}

var grid_size: int = 16

func snap_to_grid(pos: Vector2) -> Vector2:
	return (pos / grid_size).floor() * grid_size + Vector2(grid_size / 2.0, grid_size / 2.0)


func add_resource(type: String, amount: int):
	if ressource_inventory.has(type):
		ressource_inventory[type] += amount
		print("Gained ", amount, " ", type, "! Total: ", ressource_inventory[type])
		# This is where you would tell your HUD to update its text
		ressource_inventory_updated.emit()
		
	else:
		print("Error: Resource type '", type, "' doesn't exist in inventory!")

func spend_resource(type: String, amount: int) -> bool:
	if ressource_inventory.has(type):
		if ressource_inventory[type] >= amount:
			ressource_inventory[type] -= amount
			print("Spent ", amount, " ", type, "! Remaining: ", ressource_inventory[type])
			ressource_inventory_updated.emit()
			return true
		else:
			print("Not enough ", type, "!")
			return false
	else:
		print("Error: Resource type '", type, "' doesn't exist in inventory!")
		return false
