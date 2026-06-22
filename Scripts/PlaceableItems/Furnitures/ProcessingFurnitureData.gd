extends FurnitureData
class_name ProcessingFurnitureData

@export_group("Processing")
@export var resource_type: Types.ResourceType = Types.ResourceType.NONE
@export var input_item: String = ""
@export var output_item: String = ""
@export var ratio: float = 0.10
@export var production_time: float = 5.0
