extends Resource

class_name FurnitureData

@export var name: String = "New Furniture"
@export var furniture_type: String = "Misc" # Used for Habitat Recipes (e.g. "Table")
@export var costs: Dictionary = {"Wood": 10}
@export var icon: Texture2D

@export_group("Visuals")
@export var texture: Texture2D
@export var sprite_frames: SpriteFrames
@export var scale: float = 1.0

@export_group("Physics")
@export var size: Vector2i = Vector2i(1, 1)

@export_group("Production")
@export var resource_type: String = "" # e.g. "Wood"
@export var produce_amount: int = 0
@export var produce_time: float = 0.0 # 0 means no production
