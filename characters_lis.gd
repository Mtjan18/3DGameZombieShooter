extends CharacterBody3D

const SPEED = 5.0
var health: int = 100
var is_dead: bool = false
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var anim_tree = $AnimationTree 
@onready var playback = anim_tree.get("parameters/playback")
var bullet = load("res://PistolBullets.tscn")
@onready var spawn = $CharacterArmature/Skeleton3D/Middle1_L/Pistol/SpawnPistolBullets
var current_fire_rate: float = 0.5
var shoot_timer: float = 0.0
var mouse_target: Vector3 = Vector3.ZERO

func _physics_process(delta):
# --- 1. TAMBAHKAN GRAVITASI DI SINI ---
	# Jika karakter tidak menginjak lantai (is_on_floor() bernilai false), tarik ke bawah
	if not is_on_floor():
		velocity.y -= gravity * delta

	# --- 2. Pergerakan Karakter (WASD) ---
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		playback.travel("Run_Gun") 
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		playback.travel("Idle_Gun") 

	# --- 3. Eksekusi Pergerakan ---
	move_and_slide()

	look_at_mouse()
	
	if Input.is_action_just_pressed("reload"):
		reload_weapon()
	
	if shoot_timer > 0.0:
		shoot_timer -= delta
	if Input.is_action_pressed("click") and shoot_timer <= 0:
		var current_weapon = weapons_data[current_weapon_index]
		
		# JIKA SENJATA TEMBAK
		if current_weapon["type"] == "ranged":
			if current_weapon["ammo"] > 0: # Cek peluru di magazine
				current_weapon["ammo"] -= 1 # Kurangi peluru
				update_hud() # Perbarui layar
				
				# Logika memanggil peluru aslimu
				var instance = bullet.instantiate()
				get_parent().add_child(instance)
				instance.global_position = spawn.global_position
				
				if mouse_target != Vector3.ZERO:
					instance.look_at(mouse_target, Vector3.UP)
				else:
					instance.global_transform.basis = spawn.global_transform.basis
					
				shoot_timer = current_fire_rate
			else:
				# Logika jika peluru habis (bunyi klik kosong/auto reload)
				print("Peluru Habis! Tekan R untuk Reload")
				# Jangan reset shoot_timer agar pemain bisa spam klik tanpa peluru
				
		# JIKA SENJATA MELEE
		elif current_weapon["type"] == "melee":
			if velocity.length() > 0.1:
				playback.travel("Run_Slash")
			else:
				playback.travel("Slash")
			shoot_timer = current_fire_rate

func look_at_mouse():
	var camera = get_viewport().get_camera_3d()
	var mouse_pos = get_viewport().get_mouse_position()

	# PERBAIKAN 1: Letakkan bidang datar (Plane) setinggi PISTOL, bukan setinggi kaki
	var drop_plane = Plane(Vector3.UP, spawn.global_position.y)

	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_dir = camera.project_ray_normal(mouse_pos)

	var intersection = drop_plane.intersects_ray(ray_origin, ray_dir)

	if intersection != null:
		# Simpan koordinat akurat untuk arah peluru
		mouse_target = intersection
		
		# PERBAIKAN 2: Agar karakter tidak ikut mendongak/menunduk melihat tinggi pistol,
		# kita paksa titik tatapan karakter (Y) kembali setinggi badannya sendiri
		var look_pos = intersection
		look_pos.y = global_position.y 
		
		# Putar badan karakter
		look_at(look_pos, Vector3.UP)

func play_hit_animation():
	if playback:
		playback.travel("HitReact") 

# --- FUNGSI MENERIMA DAMAGE ---
func take_damage(amount):
	if is_dead:
		return
		
	health -= amount
	if health < 0: health = 0
	
	# Memanggil UIManager untuk memperbarui bar darah di layar
	var ui = get_tree().current_scene.find_child("UIManager", true, false)
	if ui and ui.has_method("update_health"):
		ui.update_health(health)
		
	if health <= 0:
		die()
		
	play_hit_animation() 
	
	if health <= 0:
		die()

# --- FUNGSI MATI / GAME OVER ---
func die():
	is_dead = true
	velocity = Vector3.ZERO # Hentikan gerakan
	
	# Mainkan animasi mati
	if playback:
		playback.travel("Death") 
		
	print("PLAYER MATI! GAME OVER.")
	
# --- SISTEM SENJATA ---
@onready var weapon_meshes = {
	"Pistol": $CharacterArmature/Skeleton3D/Middle1_L/Pistol,
	"Rifle": $CharacterArmature/Skeleton3D/Middle1_L/Rifle,
	"Melee": $CharacterArmature/Skeleton3D/Middle1_L/Axe 
}

var weapons_data = [
	{"name": "Pistol", "type": "ranged", "fire_rate": 0.5, "ammo": 15, "reserve": 30, "max_ammo": 15},
	{"name": "Rifle", "type": "ranged", "fire_rate": 0.1, "ammo": 30, "reserve": 90, "max_ammo": 30},
	{"name": "Melee", "type": "melee", "fire_rate": 0.8, "ammo": -1, "reserve": -1, "max_ammo": -1}
]

var current_weapon_index = 0

func _ready():
	for wep in weapon_meshes.values():
		wep.visible = false
	
	call_deferred("switch_weapon", 0)

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			switch_weapon(1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			switch_weapon(-1)

func switch_weapon(direction_change: int):
	var old_weapon_name = weapons_data[current_weapon_index]["name"]
	weapon_meshes[old_weapon_name].visible = false
	
	current_weapon_index += direction_change
	
	if current_weapon_index >= weapons_data.size():
		current_weapon_index = 0
	elif current_weapon_index < 0:
		current_weapon_index = weapons_data.size() - 1
		
	var current_weapon = weapons_data[current_weapon_index]
	weapon_meshes[current_weapon["name"]].visible = true
	current_fire_rate = current_weapon["fire_rate"]
	
	update_hud()

func update_hud():
	var ui = get_tree().current_scene.find_child("UIManager", true, false)
	if ui and ui.has_method("update_weapon_hud"):
		var wep = weapons_data[current_weapon_index]
		ui.update_weapon_hud(wep["name"], wep["ammo"], wep["reserve"], wep["type"] == "melee")

func reload_weapon():
	var current_weapon = weapons_data[current_weapon_index]
	
	# 1. Pastikan ini senjata api (bukan melee)
	if current_weapon["type"] == "ranged":
		
		# 2. Cek apakah peluru belum penuh DAN masih punya peluru cadangan
		if current_weapon["ammo"] < current_weapon["max_ammo"] and current_weapon["reserve"] > 0:
			
			# Hitung berapa butir peluru yang dibutuhkan untuk penuh
			var ammo_needed = current_weapon["max_ammo"] - current_weapon["ammo"]
			
			# Jika cadangan peluru cukup untuk mengisi sampai penuh
			if current_weapon["reserve"] >= ammo_needed:
				current_weapon["ammo"] += ammo_needed
				current_weapon["reserve"] -= ammo_needed
			
			# Jika sisa cadangan peluru tinggal sedikit (kurang dari yang dibutuhkan)
			else:
				current_weapon["ammo"] += current_weapon["reserve"]
				current_weapon["reserve"] = 0
				
			# Perbarui layar UI
			update_hud()
