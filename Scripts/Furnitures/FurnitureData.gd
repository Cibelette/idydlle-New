extends Resource

class_name FurnitureData

@export var name: String = "New Furniture"
@export var furniture_type: Types.FurnitureType = Types.FurnitureType.MISC # Used for Habitat Recipes (e.g. "Table")
@export var costs: Array[CostItem] = []
@export var icon: Texture2D
@export var custom_scene: PackedScene

@export_group("Visuals")
@export var texture: Texture2D
@export var sprite_frames: SpriteFrames
@export var scale: float = 1.0
@export var bubble_texture: Texture2D
@export var bubble_offset: Vector2 = Vector2(0, -32)

@export_group("Physics")
@export var size: Vector2i = Vector2i(1, 1)

@export_group("Production")
@export var resource_type: Types.ResourceType = Types.ResourceType.NONE # e.g. "Wood"
@export var produce_amount: int = 0
@export var produce_time: float = 0.0 # 0 means no production
@export var happiness: int = 0
