extends Control




func _on_backtomenu_pressed() -> void:
	MusicManager.play_sfx(preload("res://assets/audio/click.ogg"))
	get_tree().change_scene_to_file("res://main_menu.tscn")


func _on_deletesave_pressed() -> void:
	MusicManager.play_sfx(preload("res://assets/audio/click.ogg"))
	$deleteconfirm.popup_centered()
	

func _on_deleteconfirm_confirmed() -> void:
	MusicManager.play_sfx(preload("res://assets/audio/click.ogg"))
	#Global.delete_save()
	if FileAccess.file_exists(Global.save_path):
		DirAccess.remove_absolute(Global.save_path)
	
	Global.lifetime_authority = 0
	Global.authority = 0
	Global.auth_per_click = 1
	Global.passive_income = 0
	Global.passive_mult = 1
	Global.crit_chance = .05
	Global.crit_mult = 3
	Global.bloodline_strength = 0
	Global.total_bloodline_strength = 0
	Global.upgrade_passive_level = 0
	Global.upgrade_passive_cost = 50
	Global.upgrade_passive_2_level = 0
	Global.upgrade_passive_2_cost = 750
	Global.upgrade_click_level = 0
	Global.upgrade_click_cost = 10
	Global.upgrade_click_2_level = 0
	Global.upgrade_click_2_cost = 50
	Global.upgrade_crit_chance_level = 0
	Global.upgrade_crit_chance_cost = 2000
	Global.upgrade_crit_mult_level = 0
	Global.upgrade_crit_mult_cost = 5000
	var last_active_time = Time.get_unix_time_from_system()
	Global.last_active_time = last_active_time
	Global.elapsed = 0
	Global.now = 0
	Global.first_time = true
	Global.bs_perk1 = false
	Global.bs_perk2 = false
	Global.bs_perk3 = false
	SaveManager.save()
	
	
	
	
	
	
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
	print("Toggled! New value: ", Global.number_format)
	SaveManager.save()

func _ready():
	# Sync UI with current setting
	$menu/notation.button_pressed = Global.number_format == 1
	print("Global.number_format at _ready(): ", Global.number_format)
	$menu/musicvol.value = Global.music_volume
	$menu/sfxvol.value = Global.sfx_volume
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(Global.music_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(Global.sfx_volume))
	file_dialog.filters = PackedStringArray(["*.json"])
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	btn_export.pressed.connect(_on_export_pressed)
	btn_import.pressed.connect(_on_import_pressed)
	file_dialog.file_selected.connect(_on_file_selected)

	
	
func _on_musicvol_changed(value: float) -> void:
	var db = linear_to_db(value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), value)
	Global.music_volume = value
	SaveManager.save()

func _on_sfxvol_changed(value: float) -> void:
	var db = linear_to_db(value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), value)
	Global.sfx_volume = value
	SaveManager.save()
	
	
	







@onready var file_dialog: FileDialog = $FileDialog
@onready var btn_export: Button = $menu/ExportButton
@onready var btn_import: Button = $menu/ImportButton

var _pending: String = ""	# "export" or "import"




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
			get_tree().change_scene_to_file("res://scenes/game/clicker_ui.tscn")	# <- replace with your game scene
