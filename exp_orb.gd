extends Area3D

var exp_value: int = 1
var player: CharacterBody3D = null

var float_speed: float = 4.0
var float_height: float = 0.2
var time_passed: float = 0.0
var start_y: float = 0.0

# --- FITUR VACUUM ---
var is_vacuumed: bool = false
var vacuum_radius: float = 3.5
var vacuum_speed: float = 8.0

@onready var mesh = $MeshInstance3D

func _ready():
	start_y = position.y
	player = get_tree().current_scene.find_child("Player_Lis", true, false)
	body_entered.connect(_on_body_entered)
	
	# Duplikasi material agar warna orb tidak tabrakan satu sama lain
	var mat = mesh.get_active_material(0).duplicate()
	mesh.set_surface_override_material(0, mat)
	
	# Setup Warna Berdasarkan Jumlah EXP (Biru, Hijau, Emas)
	if exp_value == 1:
		mat.set_shader_parameter("base_color", Color(0.0, 0.5, 1.0)) 
	elif exp_value == 3:
		mat.set_shader_parameter("base_color", Color(0.0, 1.0, 0.2)) 
	elif exp_value >= 10:
		mat.set_shader_parameter("base_color", Color(1.0, 0.8, 0.0)) 
		
	# Mencegah map lag: Orb akan hilang otomatis jika dianggurkan selama 30 detik
	get_tree().create_timer(30.0).timeout.connect(queue_free)

func _process(delta):
	if not is_instance_valid(player): return
	
	if is_vacuumed:
		# LOGIKA PENYEDOTAN
		var target_pos = player.global_position + Vector3(0, 1.0, 0) # Bidik dada player
		global_position = global_position.move_toward(target_pos, vacuum_speed * delta)
		vacuum_speed += 15.0 * delta # Makin lamad disedot, orb meluncur makin cepat!
	else:
		# Cek Radar Sedot dengan mempertimbangkan bonus magnet dari Player
		var current_vacuum_radius = vacuum_radius
		if player.has_meta("magnet_bonus"):
			current_vacuum_radius += player.get_meta("magnet_bonus")

		if global_position.distance_to(player.global_position) <= current_vacuum_radius:
			is_vacuumed = true
		else:
			# Animasi Ngambang Santai
			time_passed += delta
			position.y = start_y + (sin(time_passed * float_speed) * float_height)

func _on_body_entered(body):
	if body.name == "Player_Lis":
		if body.has_method("add_exp"):
			body.add_exp(exp_value)
			queue_free()
