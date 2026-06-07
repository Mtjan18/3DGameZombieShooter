extends CharacterBody3D

const SPEED = 5.0

@onready var anim_tree = $AnimationTree 
@onready var playback = anim_tree.get("parameters/playback")
var bullet = load("res://PistolBullets.tscn")
@onready var spawn = $CharacterArmature/Skeleton3D/Middle1_L/Pistol/SpawnPistolBullets
var current_fire_rate: float = 0.5
var shoot_timer: float = 0.0


func _physics_process(delta):
	# 1. Pergerakan Karakter (WASD)
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Mengubah input 2D menjadi pergerakan 3D di sumbu X dan Z
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		playback.travel("Run_Gun") 
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		playback.travel("Idle_Gun") 

	move_and_slide()

	look_at_mouse()
	
	if shoot_timer > 0.0:
		shoot_timer -= delta
	if Input.is_action_pressed("click") and shoot_timer <= 0:
		var instance = bullet.instantiate()
		instance.position = spawn.global_position
		instance.transform.basis=spawn.global_transform.basis
		get_parent().add_child(instance)
		shoot_timer = current_fire_rate

func look_at_mouse():
	var camera = get_viewport().get_camera_3d()
	var mouse_pos = get_viewport().get_mouse_position()

	# 1. Buat bidang datar (Plane) yang menghadap ke atas (Vector3.UP)
	# dan letakkan persis di ketinggian (Y) karakter saat ini.
	var drop_plane = Plane(Vector3.UP, global_position.y)

	# 2. Dapatkan titik awal dan arah sinar dari kamera berdasarkan posisi mouse
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_dir = camera.project_ray_normal(mouse_pos)

	# 3. Cari titik potong (intersection) antara sinar kamera dan bidang maya tadi
	var intersection = drop_plane.intersects_ray(ray_origin, ray_dir)

	# 4. Jika menemukan titik potongnya, suruh karakter melihat ke sana
	if intersection != null:
		look_at(intersection, Vector3.UP)
		
