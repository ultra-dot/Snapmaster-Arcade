extends Node

var player_a: AudioStreamPlayer
var player_b: AudioStreamPlayer
var active_player: AudioStreamPlayer

var fade_duration: float = 2.0
var tween: Tween

var tracks = {
	"menu": preload("res://assets/Audio/ogg/What Clouds Are Made Of.ogg"),
	"wave_1": preload("res://assets/Audio/ogg/Pineapple Under The Sea.ogg"),
	"wave_2": preload("res://assets/Audio/ogg/Chickens In The Meadow.ogg"),
	"wave_3": preload("res://assets/Audio/ogg/Polar Lights.ogg"),
	"wave_4": preload("res://assets/Audio/ogg/Forgotten Biomes.ogg")
}

var current_track_name: String = ""

func _ready():
	player_a = AudioStreamPlayer.new()
	player_b = AudioStreamPlayer.new()
	
	player_a.bus = "Master"
	player_b.bus = "Master"
	
	add_child(player_a)
	add_child(player_b)
	
	active_player = player_a

func play_bgm(track_name: String):
	if track_name == current_track_name:
		return # Already playing
		
	if not tracks.has(track_name):
		print("BGM track not found: ", track_name)
		return
		
	current_track_name = track_name
	var next_player = player_b if active_player == player_a else player_a
	
	next_player.stream = tracks[track_name]
	next_player.volume_db = -60.0
	next_player.play()
	
	if tween:
		tween.kill()
		
	tween = create_tween()
	# Fade in next
	tween.tween_property(next_player, "volume_db", 0.0, fade_duration)
	
	# Fade out current if it's playing
	if active_player.playing:
		tween.parallel().tween_property(active_player, "volume_db", -60.0, fade_duration)
		tween.tween_callback(active_player.stop)
	
	active_player = next_player
