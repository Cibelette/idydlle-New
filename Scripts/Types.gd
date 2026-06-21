extends Node
class_name Types

enum ResourceType {
	NONE,
	WOOD,
	STONE,
	LEAF,
	BERRY,
	COINS,
	FRUIT
}

enum NaturalResourceType {
	MISC,
	TREE,
	ROCK,
	BUSH
}

enum FurnitureFunction {
	MISC,
	STORAGE,
	DECORATIVE,
	PROCESSING,
	CRAFTING
}

enum FurnitureType {
	MISC,
	WORKBENCH,
	STOOL,
	TABLE,
	CHEST
}

static func resource_to_string(type: ResourceType) -> String:
	match type:
		ResourceType.WOOD: return "Wood"
		ResourceType.STONE: return "Stone"
		ResourceType.LEAF: return "Leaf"
		ResourceType.BERRY: return "Berry"
		ResourceType.COINS: return "Coins"
		ResourceType.FRUIT: return "Fruit"
		_: return "None"

static func string_to_resource(s: String) -> ResourceType:
	match s.to_lower():
		"wood": return ResourceType.WOOD
		"stone": return ResourceType.STONE
		"leaf": return ResourceType.LEAF
		"berry": return ResourceType.BERRY
		"coins": return ResourceType.COINS
		"fruit": return ResourceType.FRUIT
		_: return ResourceType.NONE

static func natural_resource_to_string(type: NaturalResourceType) -> String:
	match type:
		NaturalResourceType.TREE: return "Tree"
		NaturalResourceType.ROCK: return "Rock"
		NaturalResourceType.BUSH: return "Bush"
		_: return "Misc"

static func string_to_natural_resource(s: String) -> NaturalResourceType:
	match s.to_lower():
		"tree": return NaturalResourceType.TREE
		"rock": return NaturalResourceType.ROCK
		"bush": return NaturalResourceType.BUSH
		_: return NaturalResourceType.MISC

static func furniture_function_to_string(type: FurnitureFunction) -> String:
	match type:
		FurnitureFunction.STORAGE: return "Storage"
		FurnitureFunction.DECORATIVE: return "Decorative"
		FurnitureFunction.PROCESSING: return "Processing"
		FurnitureFunction.CRAFTING: return "Crafting"
		_: return "Misc"

static func string_to_furniture_function(s: String) -> FurnitureFunction:
	match s.to_lower():
		"storage": return FurnitureFunction.STORAGE
		"decorative": return FurnitureFunction.DECORATIVE
		"processing": return FurnitureFunction.PROCESSING
		"crafting": return FurnitureFunction.CRAFTING
		_: return FurnitureFunction.MISC

static func furniture_type_to_string(type: FurnitureType) -> String:
	match type:
		FurnitureType.WORKBENCH: return "Workbench"
		FurnitureType.STOOL: return "Stool"
		FurnitureType.TABLE: return "Table"
		FurnitureType.CHEST: return "Chest"
		_: return "Misc"

static func string_to_furniture_type(s: String) -> FurnitureType:
	match s.to_lower():
		"workbench": return FurnitureType.WORKBENCH
		"stool": return FurnitureType.STOOL
		"table": return FurnitureType.TABLE
		"chest": return FurnitureType.CHEST
		_: return FurnitureType.MISC
