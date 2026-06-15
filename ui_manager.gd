extends CanvasLayer

@onready var health_bar = $HealthBar
@onready var score_label = $ScoreLabel
@onready var fade_screen = $FadeScreen
@onready var game_over_panel = $GameOverPanel
@onready var final_score_label = $GameOverPanel/FinalScore
@onready var high_score_label = $GameOverPanel/HighScore

# --- TOMBOL GAME OVER ---
@onready var retry_button = $GameOverPanel/RetryButton
@onready var menu_button = $GameOverPanel/MenuButton

@onready var weapon_name_label = $Panel/WeaponNameLabel
@onready var ammo_label = $Panel/AmmoLabel
@onready var cursor_ammo_ui = $CursorAmmoUI
@onready var exp_bar = $ExpBar
@onready var level_label = $LevelLabel

# --- VARIABEL AUDIO GAME OVER ---
@onready var game_over_audio = $GameOverPanel/GameOverAudio

var score = 0
var high_score = 0
var save_path = "user://highscore.save" 

func _ready():
	fade_screen.color.a = 0 
	game_over_panel.hide()
	load_high_score()
	
	# Hubungkan sinyal klik tombol
	if retry_button: retry_button.pressed.connect(_on_retry_pressed)
	if menu_button: menu_button.pressed.connect(_on_menu_pressed)

func add_score(points):
	score += points
	score_label.text = "Kills: " + str(score)

func show_game_over():
	if score > high_score:
		high_score = score
		save_high_score()
		
	final_score_label.text = "Skor Akhir: " + str(score)
	high_score_label.text = "Skor Tertinggi: " + str(high_score)
	
	# --- MAINKAN AUDIO GAME OVER ---
	if game_over_audio: game_over_audio.play()
	
	var tween = create_tween()
	tween.tween_property(fade_screen, "color:a", 1.0, 2.0) 
	tween.tween_callback(show_panel)

func update_health(new_health):
	if health_bar == null or not health_bar.is_inside_tree(): return
	var tween = create_tween()
	tween.tween_property(health_bar, "value", float(new_health), 0.2).set_trans(Tween.TRANS_SINE)

func update_wave_progress(zombies_killed: int):
	if wave_progress_bar == null or not wave_progress_bar.is_inside_tree(): return
	var tween = create_tween()
	tween.tween_property(wave_progress_bar, "value", float(zombies_killed), 0.2).set_trans(Tween.TRANS_SINE)

func show_panel():
	game_over_panel.show()
	
	# Sembunyikan crosshair saat mati agar klik tidak terhalang
	if cursor_ammo_ui: cursor_ammo_ui.hide()
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) 

func _on_retry_pressed():
	# MENGGUNAKAN LOADING SCREEN UNTUK RETRY
	var current_map_path = get_tree().current_scene.scene_file_path
	LoadingScreen.load_scene(current_map_path)

func _on_menu_pressed():
	# MENGGUNAKAN LOADING SCREEN UNTUK KEMBALI KE MAIN MENU
	# (Pastikan ejaan "MainMenu.tscn" sesuai dengan nama filemu)
	LoadingScreen.load_scene("res://main_menu.tscn")

func load_high_score():
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		high_score = file.get_var()
		file.close()

func save_high_score():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_var(high_score)
	file.close()
	
func update_weapon_hud(weapon_name: String, current_ammo: int, reserve_ammo: int):
	if weapon_name_label == null or ammo_label == null:
		return
	weapon_name_label.text = weapon_name
	ammo_label.text = str(current_ammo) + " / " + str(reserve_ammo)

# UI WAVE 
@onready var wave_progress_bar = $WaveProgressBar
@onready var countdown_label = $CountdownLabel

func setup_wave_ui(total_zombies: int):
	if wave_progress_bar:
		wave_progress_bar.max_value = float(total_zombies)
		wave_progress_bar.value = 0.0
	
func update_countdown(time_left: float):
	if countdown_label:
		countdown_label.show()
		countdown_label.text = "Wave Selanjutnya: " + str(ceil(time_left))

func hide_countdown():
	if countdown_label: countdown_label.hide()
	
# CursorReload
func _input(event):
	if event is InputEventMouseMotion:
		if cursor_ammo_ui and cursor_ammo_ui.visible:
			cursor_ammo_ui.global_position = event.position - Vector2(34, 0)

func setup_cursor_ammo(max_ammo: int):
	if cursor_ammo_ui:
		cursor_ammo_ui.show() 
		cursor_ammo_ui.max_value = max_ammo

func update_cursor_ammo(current_ammo: int):
	if cursor_ammo_ui:
		cursor_ammo_ui.value = current_ammo

func animate_reload_cursor(reload_time: float, target_ammo: int):
	if cursor_ammo_ui == null: return
	cursor_ammo_ui.value = 0 
	var tween = create_tween()
	tween.tween_property(cursor_ammo_ui, "value", target_ammo, reload_time)

func update_exp_bar(current: int, target: int):
	if exp_bar == null: return
	exp_bar.max_value = target
	var tween = create_tween()
	tween.tween_property(exp_bar, "value", float(current), 0.2).set_trans(Tween.TRANS_SINE)

func update_level_text(new_level: int):
	if level_label == null: return
	level_label.text = "Level " + str(new_level)
	
	level_label.scale = Vector2(1.5, 1.5)
	var tween = create_tween()
	tween.tween_property(level_label, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BOUNCE)
