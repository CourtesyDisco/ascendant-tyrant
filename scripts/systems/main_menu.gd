extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	MusicManager.play_music(preload("res://assets/audio/mainmenu.mp3"))
	print(ProjectSettings.globalize_path("user://save.json"))
	print("File exists:", FileAccess.file_exists("user://save.json"))
	var path = ProjectSettings.globalize_path("user://save.json")
	print("Trying to delete:", path)




func _on_firststart_pressed() -> void:
	MusicManager.play_sfx(preload("res://assets/audio/click.ogg"))
	get_tree().change_scene_to_file("res://scenes/gameplay/clicker_ui.tscn")
	
func _on_continue_pressed() -> void:
	MusicManager.play_sfx(preload("res://assets/audio/click.ogg"))
	get_tree().change_scene_to_file("res://scenes/gameplay/clicker_ui.tscn")

func _on_options_pressed():
	MusicManager.play_sfx(preload("res://assets/audio/click.ogg"))
	get_tree().change_scene_to_file("res://scenes/misc/options.tscn")


func _on_quit_pressed() -> void:
	MusicManager.play_sfx(load("res://audio/click.ogg"))
	get_tree().quit()
