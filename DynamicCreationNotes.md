# Dynamic Creation in Godot

In Godot, you don't *have* to have a file on disk to use a Resource or a Scene. You can create them entirely in RAM while the game is running.

### 1. Creating Resources in Code (RAM only)
If you want to "evolve" a creature or create a "Mutant Cat" with random stats, you don't need a `.tres` file. You just create a new instance of your class:

```gdscript
func create_mutant_cat():
	var mutant_data = CreatureData.new() # Create a new instance in memory
	mutant_data.species_name = "Mutant Cat"
	mutant_data.produce_amount = randi_range(50, 100) # Randomized!
	mutant_data.produce_time = 5.0
	mutant_data.resource_type = "Stone"
	
	# Now just give it to a creature
	var new_cat = load("res://Scenes/cat.tscn").instantiate()
	new_cat.data = mutant_data
	add_child(new_cat)
```

### 2. Saving to Disk (Optional)
If you want that specific "Mutant Cat" to exist forever (even after the player restarts the game), you can save it as a file:

```gdscript
func save_custom_creature(data: CreatureData, filename: String):
	var path = "user://custom_creatures/" + filename + ".tres"
	# Ensure directory exists
	DirAccess.make_dir_recursive_absolute("user://custom_creatures/")
	# Save the file
	ResourceSaver.save(data, path)
```
*Note: Use `user://` for save data, as `res://` is read-only in exported games.*

### 3. Generating Scenes Programmatically
You rarely need to "generate" a `.tscn` file. Instead, you usually have a "Base" scene and modify it at runtime:

```gdscript
func spawn_custom_object(base_scene: PackedScene, color: Color):
	var obj = base_scene.instantiate()
	obj.modulate = color # Change visual properties on the fly
	add_child(obj)
```

### When should you do this?
*   **Procedural Generation:** If you want millions of different items (like Diablo loot).
*   **User Customization:** If the player can "design" their own creature.
*   **Evolution:** If creatures gain levels and their stats change uniquely.

### Warning:
Managing hundreds of dynamically created files can make your **Save/Load system** more complex. For a simple idle game, it's usually better to have **static templates** (.tres files) and just modify a few variables (like `level` or `multiplier`) in your save file.
