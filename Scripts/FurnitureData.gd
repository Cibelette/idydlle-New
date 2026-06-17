extends Resource

class_name FurnitureData

@export var name: String = "New Furniture"
@export var furniture_type: String = "Misc" # Used for Habitat Recipes (e.g. "Table")
@export var costs: Dictionary = {"Wood": 10}
@export var scene: PackedScene
@export var icon: Texture2D

@export_group("Production")
@export var resource_type: String = "" # e.g. "Wood"
@export var produce_amount: int = 0
@export var produce_time: float = 0.0 # 0 means no production
