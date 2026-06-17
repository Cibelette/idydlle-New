extends Resource
class_name HabitatData

@export var habitat_name: String = "New Habitat"
@export var recipe: Dictionary = {} # Example: {"Table": 1, "Stool": 1}
@export var creature_scene: PackedScene # The creature to spawn
@export var max_creatures: int = 1
@export var spawn_cooldown: float = 5.0
@export var detection_radius: float = 48.0 # How close items must be to form habitat
