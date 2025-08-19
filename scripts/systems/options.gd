extends Control

@onready var file_dialog: FileDialog = $FileDialog
@onready var btn_export: Button = $menu/ExportButton
@onready var btn_import: Button = $menu/ImportButton

var _pending: String = ""	# "export" or "import"

func _ready():
	# Sync UI with current settings
	$menu/notation.button_pressed = Global.number_format == 1
	$menu/musicvol.value = Global.music_volume
	$menu/sfxvol.value = Global.sfx_volume

	# Apply current volumes (convert linear 0..1 to dB)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(Global.music_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(Global.sfx_volume))

	# File dialog setup
	file_dialog.filters = PackedStringArray(["*.json"])
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	btn_export.pressed.connect(_on_export_pressed)
	btn_import.pressed.connect(_on_import_pressed)
	file_dialog.file_selected.connect(_on_file_selected)

func _on_backtomenu_pressed() -> void:
	MusicManager.play_sfx(preload("res://assets/audio/click.ogg"))
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _on_deletesave_pressed() -> void:
	MusicManager.play_sfx(preload("res://assets/audio/click.ogg"))
	$deleteconfirm.popup_centered()

func _on_deleteconfirm_confirmed() -> void:
	MusicManager.play_sfx(preload("res://assets/audio/click.ogg"))

	# Remove the save file if it exists
	if FileAccess.file_exists(Global.save_path):
		DirAccess.remove_absolute(Global.save_path)

	# Reset runtime state safely
	if "reset_all" in Global:
		Global.reset_all()
	else:
		Global.from_dict({})  # fallback to sane defaults if helper not present

	if "reset_state" in Expansion:
		Expansion.reset_state()

	# Persist the fresh blank state so next boot is clean
	if "save" in SaveManager:
		SaveManager.save()

	# UI feedback + scene change
	$deletebackdrop.visible = true
	$deletemessage.visible = true
	$deletebackdrop.modulate = Color(0, 0, 0, 0)
	$deletemessage.modulate = Color(1, 1, 1, 0)

	var tween = create_tween()
	tween.tween_property($deletebackdrop, "modulate", Color(0, 0, 0, 1), 1.5)
	tween.tween_property($deletemessage, "modulate", Color(1, 1, 1, 1), 1.5).set_delay(0.5)

	await get_tree().create_timer(7).timeout
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _on_notation_toggled(button_pressed: bool) -> void:
	Global.number_format = 1 if button_pressed else 0
	Numberformatter.number_format = Global.number_format
	if "save_soon" in SaveManager:
		SaveManager.save_soon(2.0)
	else:
		SaveManager.save()

func _on_musicvol_changed(value: float) -> void:
	var db := linear_to_db(value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), db)
	Global.music_volume = value
	if "save_soon" in SaveManager:
		SaveManager.save_soon(2.0)
	else:
		SaveManager.save()

func _on_sfxvol_changed(value: float) -> void:
	var db := linear_to_db(value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), db)
	Global.sfx_volume = value
	if "save_soon" in SaveManager:
		SaveManager.save_soon(2.0)
	else:
		SaveManager.save()

func _on_export_pressed() -> void:
	_pending = "export"
	file_dialog.title = "Export Save"
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.current_file = "ascendant_tyrant_save.json"
	file_dialog.popup_centered()

func _on_import_pressed() -> void:
	_pending = "import"
	file_dialog.title = "Import Save"
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.popup_centered()

func _on_file_selected(path: String) -> void:
	if _pending == "export":
		if SaveManager.export_save(path):
			MusicManager.play_sfx(preload("res://assets/audio/click.ogg"))
	elif _pending == "import":
		if SaveManager.import_save(path):
			MusicManager.play_sfx(preload("res://assets/audio/click.ogg"))
			# Reload the game so it reads Global in _ready()
			get_tree().change_scene_to_file("res://scenes/game/clicker_ui.tscn")	# replace if needed
	# Clear pending state to avoid confusion on a second action
	_pending = ""
