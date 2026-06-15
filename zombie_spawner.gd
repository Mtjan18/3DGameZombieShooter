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

var total_zombies_in_wave: int = 0
var zombies_killed: int = 0
var is_resting: bool = false
var rest_time_left: float = 0.0

func _ready():
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	start_rest_time()

func _process(delta):
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
	rest_time_left = 3.0

# LOGIKA WAVE
func start_wave(wave: int):
	print("--- MEMULAI WAVE ", wave, " ---")
	zombies_killed = 0
	
	# 1. TENTUKAN JUMLAH ZOMBIE BERDASARKAN TIPE WAVE
	if wave % 7 == 6: # WAVE 6, 13, 20 (Relaksasi, Drop Rate Tinggi)
		total_zombies_in_wave = 10 + (wave * 2) 
	elif wave % 7 == 0: # WAVE 7, 14, 21 (BOSS WAVE)
		total_zombies_in_wave = 12 + (wave * 2) 
	else: # WAVE NORMAL
		total_zombies_in_wave = 15 + (wave * 5) + int(pow(wave, 1.2))

	# 2. TENTUKAN KECEPATAN SPAWN
	var new_wait_time = max(0.3, 1.5 - (wave * 0.05))
	if wave % 7 == 6: new_wait_time = 1.0 # Keluar lambat pas relaksasi
	spawn_timer.wait_time = new_wait_time
	
	# 3. KOMPOSISI ZOMBIE
	if wave % 7 == 0:
		# BOSS BATTLE: Boss muncul sesuai kelipatan (Wave 7 = 1, Wave 14 = 2, dll)
		arm2_queue = max(1, int(wave / 7)) 
		chubby_queue = int(total_zombies_in_wave * 0.3)
		basic_queue = total_zombies_in_wave - arm2_queue - chubby_queue
	elif wave % 4 == 0:
		# Banyak Chubby
		chubby_queue = int(total_zombies_in_wave * 0.5)
		arm2_queue = 0
		basic_queue = total_zombies_in_wave - chubby_queue
	else:
		# WAVE NORMAL TERGANTUNG LEVEL
		if wave <= 3:
			basic_queue = total_zombies_in_wave
			chubby_queue = 0
			arm2_queue = 0
		elif wave <= 5:
			chubby_queue = int(total_zombies_in_wave * 0.2)
			arm2_queue = 0
			basic_queue = total_zombies_in_wave - chubby_queue
		else:
			# Normal mix untuk wave tinggi (Sesekali ada elite Arm2)
			var chubby_percent = min(0.30, 0.10 + (wave * 0.01))
			var arm2_percent = min(0.10, 0.01 + (wave * 0.005))
			
			chubby_queue = int(total_zombies_in_wave * chubby_percent)
			arm2_queue = int(total_zombies_in_wave * arm2_percent)
			basic_queue = total_zombies_in_wave - arm2_queue - chubby_queue

	if basic_queue < 0: basic_queue = 0
	
	var ui = get_tree().current_scene.find_child("UIManager", true, false)
	if ui and ui.has_method("setup_wave_ui"):
		ui.setup_wave_ui(total_zombies_in_wave)
	
	spawn_timer.start()

func _on_spawn_timer_timeout():
	var zombie_to_spawn: PackedScene = null
	var type_selected = ""
	
	if basic_queue > 0:
		zombie_to_spawn = basic_zombie_scene
		type_selected = "basic"
		basic_queue -= 1
	elif chubby_queue > 0:
		zombie_to_spawn = chubby_zombie_scene
		type_selected = "chubby"
		chubby_queue -= 1
	elif arm2_queue > 0:
		zombie_to_spawn = arm2_zombie_scene
		type_selected = "arm2"
		arm2_queue -= 1
	else:
		spawn_timer.stop() 
		return
		
	if not spawn_zombie(zombie_to_spawn):
		if type_selected == "basic": basic_queue += 1
		elif type_selected == "chubby": chubby_queue += 1
		elif type_selected == "arm2": arm2_queue += 1

func spawn_zombie(zombie_scene: PackedScene) -> bool:
	if player == null or zombie_scene == null: return false
	
	var map = get_world_3d().navigation_map
	var final_spawn_pos = Vector3.ZERO
	var is_valid_position = false
	
	for i in range(10):
		var random_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
		var random_dist = randf_range(12.0, 25.0)
		var target_pos = player.global_position + (random_dir * random_dist)
		target_pos.y = player.global_position.y 
		
		var test_pos = NavigationServer3D.map_get_closest_point(map, target_pos)
		
		if abs(test_pos.y - player.global_position.y) < 1:
			final_spawn_pos = test_pos
			is_valid_position = true
			break 
			
	if not is_valid_position: return false 
	
	var instance = zombie_scene.instantiate()
	get_parent().add_child(instance)
	instance.global_position = final_spawn_pos
	
	if instance.has_method("setup_stats"):
		instance.setup_stats(current_wave)
		
	active_zombies_in_map += 1
	return true 

func on_zombie_killed():
	active_zombies_in_map -= 1
	zombies_killed += 1
	
	var ui = get_tree().current_scene.find_child("UIManager", true, false)
	if ui and ui.has_method("update_wave_progress"):
		ui.update_wave_progress(zombies_killed)
		
	if zombies_killed >= total_zombies_in_wave:
		current_wave += 1 
		start_rest_time()
