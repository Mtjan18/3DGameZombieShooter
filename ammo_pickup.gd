extends Area3D

var weapon_type: String = "Pistol"
var ammo_amount: int = 10

var float_speed: float = 3.0
var float_height: float = 0.3
var time_passed: float = 0.0
var start_y: float = 0.0

@onready var mesh = $Pickup_Bullets

# Waktu sebelum peluru hilang dari map (dalam detik)
var lifespan: float = 15.0 

func _ready():
	start_y = global_position.y
	
	# MENDUPLIKASI MATERIAL: Agar warna peluru independen dan tidak mengubah peluru lain di arena
	var mat = mesh.get_active_material(0).duplicate()
	mesh.set_surface_override_material(0, mat)
	
	if randf() > 0.5:
		weapon_type = "Pistol"
		ammo_amount = 10
		# Ubah parameter shader menjadi kuning (R, G, B)
		mat.set_shader_parameter("base_color", Color(1.0, 0.8, 0.0)) 
	else:
		weapon_type = "Rifle"
		ammo_amount = 20
		# Ubah parameter shader menjadi biru terang
		mat.set_shader_parameter("base_color", Color(0.0, 0.6, 1.0)) 
		
	body_entered.connect(_on_body_entered)
	
	# Mulai proses penghancuran diri otomatis
	start_despawn_timer()

func _process(delta):
	rotate_y(deg_to_rad(90) * delta)
	time_passed += delta
	global_position.y = start_y + (sin(time_passed * float_speed) * float_height)

func _on_body_entered(body):
	if body.name == "Player_Lis":
		if body.has_method("add_ammo"):
			body.add_ammo(weapon_type, ammo_amount)
			queue_free() # Hilangkan peluru segera setelah disentuh

# --- FITUR KADALUARSA (DESPAWN) ---
func start_despawn_timer():
	# 1. Biarkan diam bersinar di map selama (lifespan - 3) detik
	await get_tree().create_timer(lifespan - 3.0).timeout
	
	# 2. Pada 3 detik terakhir, buat pelurunya berkedip-kedip sebagai peringatan!
	for i in range(6): 
		# PENTING: Cek dulu apakah peluru ini belum diambil oleh player di sela-sela waktu kedipnya
		if not is_instance_valid(self): return 
		
		mesh.visible = not mesh.visible
		await get_tree().create_timer(0.5).timeout
		
	# 3. Waktu benar-benar habis, hapus dari memori
	if is_instance_valid(self):
		queue_free()
