class_name Utils
extends Node

## Helper function to find all files with a specific extension in a directory and its subdirectories
static func get_files_recursive(path: String, extension: String) -> Array[String]:
	var files: Array[String] = []
	if not path.ends_with("/"):
		path += "/"

	if not DirAccess.dir_exists_absolute(path):
		return files

	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				files.append_array(get_files_recursive(path + file_name + "/", extension))
			else:
				# In exported builds, files inside the PCK may end with .remap or .import
				var clean_name = file_name
				if clean_name.ends_with(".remap"):
					clean_name = clean_name.trim_suffix(".remap")
				elif clean_name.ends_with(".import"):
					clean_name = clean_name.trim_suffix(".import")
				
				if clean_name.ends_with(extension):
					var full_path = path + clean_name
					if not files.has(full_path):
						files.append(full_path)
			file_name = dir.get_next()
	return files
