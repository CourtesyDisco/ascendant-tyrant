extends Node

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1

signal save_loaded
signal save_saved
signal save_exported
signal save_imported

func _snapshot() -> Dictionary:
	var d: Dictionary = Global.to_dict()
	d["__version"] = SAVE_VERSION
	return d

func _apply(data: Dictionary) -> void:
	# migrations would go here if SAVE_VERSION changes
	Global.from_dict(data)
	save_loaded.emit()

func save() -> void:
	var json: String = JSON.stringify(_snapshot())
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(json)
	f.close()
	save_saved.emit()

func load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var text: String = f.get_as_text()
	f.close()

	var data: Variant = JSON.parse_string(text)
	if typeof(data) == TYPE_DICTIONARY:
		_apply(data as Dictionary)

func export_save(path: String) -> bool:
	var json: String = JSON.stringify(_snapshot())
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(json)
	f.close()
	save_exported.emit()
	return true

func import_save(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var text: String = f.get_as_text()
	f.close()

	var data: Variant = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		return false
	_apply(data as Dictionary)
	save()	# persist imported data to main save path
	save_imported.emit()
	return true


var _pending := false
var _debounce: SceneTreeTimer

func save_soon(delay := 8.0) -> void:
	if _pending: return
	_pending = true
	_debounce = get_tree().create_timer(delay)
	_debounce.timeout.connect(func():
		_pending = false
		save()
	)
	
	
	
