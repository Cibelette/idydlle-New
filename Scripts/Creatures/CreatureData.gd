extends Resource

class_name CreatureData # This turns it into a "Class" you can use everywhere

@export var species_name: String = "New Creature"
@export var icon: Texture2D # For the cute art
@export var sprite_frames: SpriteFrames # Visual animations
@export var scale: float = 1.0 # Size of the creature
@export var produce_amount: int = 1
@export var produce_time: float = 10.0 # How many seconds it takes to work
@export var resource_type: Types.ResourceType = Types.ResourceType.WOOD # Wood, Stone, etc.
@export var fonction: Types.CreatureFunction = Types.CreatureFunction.FARMING
@export var sound_text: String = "Hello!"
