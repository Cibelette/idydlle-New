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
				if file_name.ends_with(extension):
					files.append(path + file_name)
			file_name = dir.get_next()
	return files
