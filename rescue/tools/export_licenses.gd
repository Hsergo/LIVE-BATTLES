extends SceneTree

func _initialize() -> void:
	var destination := OS.get_environment("RESCUE_LICENSE_DIR")
	if destination.is_empty():
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(destination)
	var file := FileAccess.open(destination.path_join("GODOT-LICENSES.txt"),FileAccess.WRITE)
	if file == null:
		quit(1)
		return
	file.store_string(Engine.get_license_text()+"\n\nTHIRD-PARTY LICENSES\n")
	var licenses := Engine.get_license_info()
	for key in licenses:
		file.store_string("\n\n"+str(key)+"\n"+str(licenses[key]))
	file.close()
	quit()
