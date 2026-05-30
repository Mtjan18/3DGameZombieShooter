extends Camera3D

@export var player: CharacterBody3D 
var offset: Vector3 = Vector3(0, 14, 8)
var currently_hidden_building: Node3D = null

func _ready():
	if player:
		offset = global_position - player.global_position

func _physics_process(delta):
	if player:
		var target_pos = player.global_position + offset
		global_position = global_position.lerp(target_pos, delta * 5.0)
		check_view_obstruction()

func check_view_obstruction():
	var space_state = get_world_3d().direct_space_state
	
	var camera_pos = global_position
	var target_pos = player.global_position + Vector3(0, 1.0, 0)
	
	# --- IMPLEMENTASI IDE KAMU: Memundurkan titik awal Raycast ---
	# 1. Dapatkan arah (direction) dari Player menunjuk ke Kamera
	var direction = (camera_pos - target_pos).normalized()
	
	# 2. Tarik titik 'from' mundur sejauh 30 meter di belakang kamera
	# (Angka 30.0 bisa kamu besarkan jika gedungmu SANGAT besar)
	var pullback_distance = 30.0 
	var from = camera_pos + (direction * pullback_distance)
	
	# Titik akhir (to) tetap ke arah Player
	var to = target_pos
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1 
	
	# 3. [PENTING DI GODOT 4] Paksa Godot membaca tabrakan dari dalam/belakang objek
	query.hit_back_faces = true
	query.hit_from_inside = true
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var collider = result.collider
		var building_root = find_building_root(collider)
		
		if building_root != null and building_root != currently_hidden_building:
			if currently_hidden_building != null:
				currently_hidden_building.visible = true
				
			building_root.visible = false
			currently_hidden_building = building_root
			
	else:
		if currently_hidden_building != null:
			currently_hidden_building.visible = true
			currently_hidden_building = null
			
# --- FUNGSI BARU ---
func find_building_root(node: Node) -> Node:
	var current = node
	
	# Looping: Terus naik ke parent selama node-nya ada
	while current != null:
		# 1. Jika node ini punya tanda/grup "Building", berhenti dan laporkan!
		if current.is_in_group("Building"):
			return current
			
		# 2. Safety lock: Jika mentok sampai "RootNode", batalkan pencarian
		if current.name == "RootNode":
			return null
			
		# 3. Naik satu tingkat ke atas
		current = current.get_parent()
		
	return null
