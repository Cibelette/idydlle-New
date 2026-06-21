extends Resource
class_name PlaceableItemData

@export var name: String = "New Placeable"
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
