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

enum FurnitureType {
	MISC,
	STORAGE,
	TABLE,
	STOOL,
	TREE,
	ZONE,
	ROCK
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

static func furniture_to_string(type: FurnitureType) -> String:
	match type:
		FurnitureType.STORAGE: return "Storage"
		FurnitureType.TABLE: return "Table"
		FurnitureType.STOOL: return "Stool"
		FurnitureType.TREE: return "Tree"
		FurnitureType.ZONE: return "Zone"
		FurnitureType.ROCK: return "Rock"
		_: return "Misc"

static func string_to_furniture(s: String) -> FurnitureType:
	match s.to_lower():
		"Storage": return FurnitureType.STORAGE
		"table": return FurnitureType.TABLE
		"stool": return FurnitureType.STOOL
		"tree": return FurnitureType.TREE
		"zone": return FurnitureType.ZONE
		"rock": return FurnitureType.ROCK
		_: return FurnitureType.MISC
