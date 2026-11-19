extends RefCounted
## Checksum, atomic replacement and one last-good backup. Never stores API keys.
const MAX_BYTES := 1048576
var error_message := ""
var used_backup := false

func save_game(model: RefCounted, path: String) -> bool:
	error_message = ""
	var payload := JSON.stringify(model.call("snapshot"))
	var envelope := JSON.stringify({"version":1,"payload":payload,"sha256":payload.sha256_text()})
	if envelope.to_utf8_buffer().size() > MAX_BYTES:
		error_message = "Sauvegarde trop volumineuse"
		return false
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file == null:
		error_message = "Impossible d'ecrire la sauvegarde"
		return false
	file.store_string(envelope)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		error_message = "Ecriture incomplete de la sauvegarde"
		return false
	var target := ProjectSettings.globalize_path(path)
	var backup := target+".bak"
	# Preserve a valid backup if the current primary was damaged.
	if FileAccess.file_exists(path) and not _read(path).is_empty():
		if FileAccess.file_exists(backup):
			DirAccess.remove_absolute(backup)
		if DirAccess.rename_absolute(target,backup) != OK:
			error_message = "Impossible de conserver la sauvegarde precedente"
			return false
	elif FileAccess.file_exists(path):
		DirAccess.remove_absolute(target)
	if DirAccess.rename_absolute(target+".tmp",target) != OK:
		if FileAccess.file_exists(backup):
			DirAccess.copy_absolute(backup,target)
		error_message = "Impossible de finaliser la sauvegarde"
		return false
	return true

func load_game(model: RefCounted, path: String) -> bool:
	error_message = ""
	used_backup = false
	for candidate in [path,path+".bak"]:
		var data := _read(candidate)
		if not data.is_empty() and bool(model.call("restore",data)):
			used_backup = candidate.ends_with(".bak")
			return true
	error_message = "Aucune sauvegarde valide disponible"
	return false

func _read(path: String) -> Dictionary:
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null or file.get_length() > MAX_BYTES:
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {}
	var raw = parser.data
	if typeof(raw) != TYPE_DICTIONARY or int(raw.get("version",0)) != 1:
		return {}
	if typeof(raw.get("payload")) != TYPE_STRING or typeof(raw.get("sha256")) != TYPE_STRING:
		return {}
	var payload: String = raw["payload"]
	if payload.sha256_text() != raw["sha256"]:
		return {}
	if parser.parse(payload) != OK:
		return {}
	var data = parser.data
	return data if typeof(data) == TYPE_DICTIONARY else {}
