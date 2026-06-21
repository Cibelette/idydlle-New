extends Resource
class_name RecipeItem

enum RecipeMode { FURNITURE, NATURAL_RESOURCE }

@export var mode: RecipeMode = RecipeMode.FURNITURE
@export var furniture_type: Types.FurnitureType = Types.FurnitureType.MISC
@export var natural_resource_type: Types.NaturalResourceType = Types.NaturalResourceType.MISC
@export var amount: int = 1
