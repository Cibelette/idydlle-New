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

enum PlaceableType {
	MISC,
	STORAGE,
	TABLE,
	STOOL,
	TREE,
	ZONE,
	ROCK,
	BUSH
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

static func placeable_to_string(type: PlaceableType) -> String:
	match type:
		PlaceableType.STORAGE: return "Storage"
		PlaceableType.TABLE: return "Table"
		PlaceableType.STOOL: return "Stool"
		PlaceableType.TREE: return "Tree"
		PlaceableType.ZONE: return "Zone"
		PlaceableType.ROCK: return "Rock"
		PlaceableType.BUSH: return "Bush"
		_: return "Misc"

static func string_to_placeable(s: String) -> PlaceableType:
	match s.to_lower():
		"Storage": return PlaceableType.STORAGE
		"table": return PlaceableType.TABLE
		"stool": return PlaceableType.STOOL
		"tree": return PlaceableType.TREE
		"zone": return PlaceableType.ZONE
		"rock": return PlaceableType.ROCK
		"bush": return PlaceableType.BUSH
		_: return PlaceableType.MISC
