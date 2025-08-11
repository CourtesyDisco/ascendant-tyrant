extends Node


@onready var music_player = $MusicPlayer
@onready var sfx_player = $SFXPlayer

var is_music_muted = false
var is_sfx_muted = false

func play_music(track: AudioStream):
	if not is_music_muted:
		music_player.stream = track
		music_player.play()

func stop_music():
	music_player.stop()

func play_sfx(sound: AudioStream):
	if not is_sfx_muted:
		sfx_player.stream = sound
		sfx_player.play()

func set_music_volume(db: float):
	music_player.volume_db = db

func set_sfx_volume(db: float):
	sfx_player.volume_db = db
	
func _ready():
	music_player.connect("finished", Callable(self, "_on_music_finished"))
	
func _on_music_finished():
	if music_player.stream:  
		music_player.play()

func set_bus_volume(bus_name: String, value: float) -> void:
	var db = linear_to_db(clamp(value, 0.0, 1.0))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name), db)
