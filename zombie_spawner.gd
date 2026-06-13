extends Node3D

@export var player: CharacterBody3D
@export var basic_zombie_scene: PackedScene
@export var chubby_zombie_scene: PackedScene
@export var arm2_zombie_scene: PackedScene

@onready var spawn_timer = $SpawnTimer

var current_wave: int = 1
var active_zombies_in_map: int = 0 

var basic_queue: int = 0
var chubby_queue: int = 0
var arm2_queue: int = 0

# --- VARIABEL BARU UNTUK PROGRESS WAVE ---
var total_zombies_in_wave: int = 0
var zombies_killed: int = 0
var is_resting: bool = false
var rest_time_left: float = 0.0

func _ready():
	spawn_timer.wait_time = 1.5
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	
	# Delay 3 detik pertama sebelum Wave 1 dimulai
	start_rest_time()

func _process(delta):
	# Logika menghitung mundur jeda antar wave
	if is_resting:
		rest_time_left -= delta
		
		var ui = get_tree().current_scene.find_child("UIManager", true, false)
		if ui and ui.has_method("update_countdown"):
			ui.update_countdown(rest_time_left)
			
		if rest_time_left <= 0:
			is_resting = false
			if ui: ui.hide_countdown()
			start_wave(current_wave)

func start_rest_time():
	is_resting = true
	rest_time_left = 3.0 # Waktu jeda 3 detik

func start_wave(wave: int):
	print("--- MEMULAI WAVE ", wave, " ---")
	zombies_killed = 0
	
	total_zombies_in_wave = 20 + (wave * 5)
	arm2_queue = min(wave / 3, 5) 
	
	if wave >= 2:
		chubby_queue = 2 + (wave * 2)
	else:
		chubby_queue = 0
		
	basic_queue = total_zombies_in_wave - arm2_queue - chubby_queue
	
	# Setup UI Progress Bar
	var ui = get_tree().current_scene.find_child("UIManager", true, false)
	if ui and ui.has_method("setup_wave_ui"):
		ui.setup_wave_ui(total_zombies_in_wave)
	
	spawn_timer.start()

func _on_spawn_timer_timeout():
	var zombie_to_spawn: PackedScene = null
	
	if basic_queue > 0:
		zombie_to_spawn = basic_zombie_scene
		basic_queue -= 1
	elif chubby_queue > 0:
		zombie_to_spawn = chubby_zombie_scene
		chubby_queue -= 1
	elif arm2_queue > 0:
		zombie_to_spawn = arm2_zombie_scene
		arm2_queue -= 1
	else:
		spawn_timer.stop() 
		return
		
	spawn_zombie(zombie_to_spawn)

func spawn_zombie(zombie_scene: PackedScene):
	if player == null or zombie_scene == null: return
	
	var map = get_world_3d().navigation_map
	var final_spawn_pos = Vector3.ZERO
	var is_valid_position = false
	
	# SISTEM KOCOK ULANG (Maksimal 10 kali percobaan agar game tidak lag/hang)
	for i in range(10):
		var random_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
		var random_dist = randf_range(10.0, 20.0)
		var target_pos = player.global_position + (random_dir * random_dist)
		target_pos.y = player.global_position.y 
		
		var test_pos = NavigationServer3D.map_get_closest_point(map, target_pos)
		
		# CEK KETINGGIAN: Apakah titik hasil pencarian tingginya hampir sama dengan kaki player?
		# (Toleransi 1.5 meter untuk mengantisipasi trotoar atau jalanan yang sedikit menanjak)
		if abs(test_pos.y - player.global_position.y) < 1.5:
			final_spawn_pos = test_pos
			is_valid_position = true
			break # Titik valid ditemukan! Langsung hentikan proses kocok ulang.
			
	# Jika setelah 10x percobaan tetap gagal (misal player sedang terpojok di ruangan tertutup),
	# batalkan kemunculan zombie kali ini agar tidak nyangkut di atap.
	if not is_valid_position:
		return
	
	# Jika valid, cetak zombienya!
	var instance = zombie_scene.instantiate()
	get_parent().add_child(instance)
	instance.global_position = final_spawn_pos
	active_zombies_in_map += 1

# --- FUNGSI BARU: DIPANGGIL SAAT ZOMBIE MATI ---
func on_zombie_killed():
	active_zombies_in_map -= 1
	zombies_killed += 1
	
	# Isi bar darahnya
	var ui = get_tree().current_scene.find_child("UIManager", true, false)
	if ui and ui.has_method("update_wave_progress"):
		ui.update_wave_progress(zombies_killed)
		
	# Jika semua zombie di wave ini sudah mati
	if zombies_killed >= total_zombies_in_wave:
		current_wave += 1 # Naikkan level wave
		start_rest_time() # Mulai jeda 3 detik
