extends Control

@onready var btn_play = $CenterContainer/VBoxMain/ButtonBox/PlayBtn
@onready var btn_quit = $CenterContainer/VBoxMain/ButtonBox/QuitBtn
@onready var bgm_audio = $BGMAudio

func _ready():
	get_tree().paused = false
	
	# mainkan musik
	bgm_audio.play()
	
	# Hubungkan tombol
	btn_play.pressed.connect(_on_play_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)

func _on_play_pressed():
	LoadingScreen.load_scene("res://MainMap.tscn")

func _on_quit_pressed():
	get_tree().quit()
