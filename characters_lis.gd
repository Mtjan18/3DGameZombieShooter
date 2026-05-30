extends CharacterBody3D

const SPEED = 5.0

@onready var anim_tree = $AnimationTree 
@onready var playback = anim_tree.get("parameters/playback")

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

func look_at_mouse():
	# Mengambil posisi kursor dan menembakkan garis imajiner (Raycast) dari Kamera ke lantai 3D
	var camera = get_viewport().get_camera_3d()
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_length = 1000.0

	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * ray_length

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	
	query.collision_mask = 2
	
	# Opsional: Pastikan raycast hanya menabrak lantai (bisa diset collision mask-nya)
	var result = space_state.intersect_ray(query)

	if result:
		var look_pos = result.position
		# Kunci sumbu Y agar karakter tidak menunduk ke lantai atau mendongak ke langit
		look_pos.y = global_position.y 
		look_at(look_pos, Vector3.UP)
