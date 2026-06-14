extends Control

@onready var btn_play = $CenterContainer/VBoxMain/ButtonBox/PlayBtn
@onready var btn_quit = $CenterContainer/VBoxMain/ButtonBox/QuitBtn

# --- VARIABEL BGM ---
@onready var bgm_audio = $BGMAudio

func _ready():
	# Memastikan waktu berjalan normal (berjaga-jaga jika pemain kembali dari layar Pause Menu)
	get_tree().paused = false
	
	# Mainkan musik latar belakang saat menu dibuka
	bgm_audio.play()
	
	# Hubungkan tombol
	btn_play.pressed.connect(_on_play_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)

func _on_play_pressed():
	# Ganti "MainMap.tscn" dengan nama persis scene utama peta game kamu
	get_tree().change_scene_to_file("res://MainMap.tscn")

func _on_quit_pressed():
	# Keluar dari aplikasi game
	get_tree().quit()
