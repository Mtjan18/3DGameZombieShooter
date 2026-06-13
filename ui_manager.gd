extends CanvasLayer

@onready var health_bar = $HealthBar
@onready var score_label = $ScoreLabel
@onready var fade_screen = $FadeScreen
@onready var game_over_panel = $GameOverPanel
@onready var final_score_label = $GameOverPanel/FinalScore
@onready var high_score_label = $GameOverPanel/HighScore
@onready var retry_button = $GameOverPanel/RetryButton
@onready var weapon_name_label = $Panel/WeaponNameLabel
@onready var ammo_label = $Panel/AmmoLabel
@onready var cursor_ammo_ui = $CursorAmmoUI
@onready var exp_bar = $ExpBar
@onready var level_label = $LevelLabel

var score = 0
var high_score = 0
var save_path = "user://highscore.save" # Lokasi penyimpanan skor di komputer

func _ready():
	fade_screen.color.a = 0 # Layar transparan saat mulai
	game_over_panel.hide()
	load_high_score()
	retry_button.pressed.connect(_on_retry_pressed)

# Fungsi untuk menambah skor (dipanggil saat zombie mati)
func add_score(points):
	score += points
	score_label.text = "Kills: " + str(score)

# Fungsi untuk memicu layar Game Over
func show_game_over():
	# Cek rekor baru
	if score > high_score:
		high_score = score
		save_high_score()
		
	final_score_label.text = "Skor Akhir: " + str(score)
	high_score_label.text = "Skor Tertinggi: " + str(high_score)
	
	# Efek layar meredup ke hitam (Tween)
	var tween = create_tween()
	tween.tween_property(fade_screen, "color:a", 1.0, 2.0) # Berubah jadi hitam dalam 2 detik
	tween.tween_callback(show_panel)

func update_health(new_health):
	if health_bar == null or not health_bar.is_inside_tree(): return
	var tween = create_tween()
	# PENTING: Tambahkan float()
	tween.tween_property(health_bar, "value", float(new_health), 0.2).set_trans(Tween.TRANS_SINE)

# ... (kode lainnya tetap sama) ...

func update_wave_progress(zombies_killed: int):
	if wave_progress_bar == null or not wave_progress_bar.is_inside_tree(): return
	var tween = create_tween()
	# PENTING: Tambahkan float()
	tween.tween_property(wave_progress_bar, "value", float(zombies_killed), 0.2).set_trans(Tween.TRANS_SINE)

func show_panel():
	game_over_panel.show()
	# Munculkan kursor mouse untuk klik tombol Retry
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) 

func _on_retry_pressed():
	get_tree().reload_current_scene() # Mengulang peta dari awal

# Sistem Save/Load Highscore
func load_high_score():
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		high_score = file.get_var()
		file.close()

func save_high_score():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_var(high_score)
	file.close()
	
func update_weapon_hud(weapon_name: String, current_ammo: int, reserve_ammo: int, is_melee: bool):
	if weapon_name_label == null or ammo_label == null:
		return
	weapon_name_label.text = weapon_name
	
	if is_melee:
		ammo_label.text = "∞" 
	else:
		ammo_label.text = str(current_ammo) + " / " + str(reserve_ammo)


# UI WAVE 
@onready var wave_progress_bar = $WaveProgressBar
@onready var countdown_label = $CountdownLabel

# Mengatur panjang bar sesuai total zombie
func setup_wave_ui(total_zombies: int):
	wave_progress_bar.max_value = total_zombies
	wave_progress_bar.value = 0
	
# Menampilkan hitung mundur
func update_countdown(time_left: float):
	countdown_label.show()
	countdown_label.text = "Wave Selanjutnya: " + str(ceil(time_left))

# Menyembunyikan hitung mundur
func hide_countdown():
	countdown_label.hide()
	
	
#CursorReload
func _input(event):
	# Jika ada pergerakan mouse
	if event is InputEventMouseMotion:
		if cursor_ammo_ui and cursor_ammo_ui.visible:
			# Ukuran donat pasti 64x64, maka titik tengahnya adalah ditarik mundur 32 pixel
			cursor_ammo_ui.global_position = event.position - Vector2(34, 0)

# Mengatur kapasitas maksimal donat saat ganti senjata
func setup_cursor_ammo(max_ammo: int, is_melee: bool):
	if is_melee:
		cursor_ammo_ui.hide() # Sembunyikan donat kalau pakai Melee
	else:
		cursor_ammo_ui.show()
		cursor_ammo_ui.max_value = max_ammo

# Mengurangi donat seketika saat peluru ditembakkan
func update_cursor_ammo(current_ammo: int):
	cursor_ammo_ui.value = current_ammo

# Memutar animasi donat terisi pelan-pelan selama reload
func animate_reload_cursor(reload_time: float, target_ammo: int):
	cursor_ammo_ui.value = 0 # Kosongkan donat dulu
	var tween = create_tween()
	# Isi donat dari 0 ke jumlah peluru baru dalam waktu "reload_time" (3 detik)
	tween.tween_property(cursor_ammo_ui, "value", target_ammo, reload_time)
	


func update_exp_bar(current: int, target: int):
	exp_bar.max_value = target
	var tween = create_tween()
	tween.tween_property(exp_bar, "value", float(current), 0.2).set_trans(Tween.TRANS_SINE)

func update_level_text(new_level: int):
	level_label.text = "Level " + str(new_level)
	
	# Efek pop up membesar sedikit saat naik level agar memuaskan
	level_label.scale = Vector2(1.5, 1.5)
	var tween = create_tween()
	tween.tween_property(level_label, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BOUNCE)
