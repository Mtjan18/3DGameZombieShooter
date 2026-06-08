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
	
	if shoot_timer > 0.0:
		shoot_timer -= delta
	if Input.is_action_pressed("click") and shoot_timer <= 0:
		var instance = bullet.instantiate()
		get_parent().add_child(instance)
		
		# Set posisi awal peluru
		instance.global_position = spawn.global_position
		
		# PERBAIKAN 3: Arahkan peluru langsung ke target mouse yang sejajar
		if mouse_target != Vector3.ZERO:
			instance.look_at(mouse_target, Vector3.UP)
		else:
			instance.global_transform.basis = spawn.global_transform.basis
			
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
