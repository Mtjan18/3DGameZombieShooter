extends CanvasLayer

@onready var health_bar = $HealthBar
@onready var score_label = $ScoreLabel
@onready var fade_screen = $FadeScreen
@onready var game_over_panel = $GameOverPanel
@onready var final_score_label = $GameOverPanel/FinalScore
@onready var high_score_label = $GameOverPanel/HighScore
@onready var retry_button = $GameOverPanel/RetryButton

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
	# Menggunakan Tween agar bar darah menyusut dengan animasi yang halus selama 0.2 detik
	var tween = create_tween()
	
	# Transisi halus (SINE) dari nilai bar saat ini menuju nilai new_health
	tween.tween_property(health_bar, "value", new_health, 0.2).set_trans(Tween.TRANS_SINE)

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
