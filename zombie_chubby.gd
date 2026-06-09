extends CharacterBody3D

# --- STATISTIK ZOMBIE DINAMIS ---
# SPEED tidak lagi const, agar bisa diubah kecepatannya saat randomize
var current_speed: float = 3.0 
var health = 3 
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# --- VARIABEL ANIMASI ---
var move_anim: String = "Walk"
var attack_anim: String = "Punch"

# --- REFERENSI NODE ---
@onready var nav_agent = $NavigationAgent3D
@onready var anim_player = $AnimationPlayer 

var player: CharacterBody3D = null

# --- PENGATURAN SERANGAN ---
var attack_distance = 2.0
var can_attack = true
var attack_cooldown = 1.5

# --- STATUS ZOMBIE ---
var is_dead = false 
var is_hit = false 

func _ready():
	player = get_tree().current_scene.find_child("Player_Lis", true, false)
	# Panggil fungsi pengocok tipe saat zombie baru saja dilahirkan oleh Spawner
	randomize_zombie_type()

# --- FUNGSI ACAK TIPE (VARIASI ZOMBIE) ---
func randomize_zombie_type():
	var random_type = randi() % 3 + 1 # Mengocok angka 1, 2, atau 3
	
	if random_type == 1:
		current_speed = 1.0
		move_anim = "Walk"
		attack_anim = "Punch"
	elif random_type == 2:
		current_speed = 2.0
		move_anim = "Run"
		attack_anim = "Run_Attack"
	else:
		current_speed = 3.0
		move_anim = "Run_Arms"
		attack_anim = "Run_Attack"

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if is_dead or is_hit:
		move_and_slide() 
		return

	if player == null:
		return

	var distance_to_player = global_position.distance_to(player.global_position)

	# --- JARAK SERANG ---
	if distance_to_player <= attack_distance:
		velocity = Vector3.ZERO 
		var look_at_pos = Vector3(player.global_position.x, global_position.y, player.global_position.z)
		if global_position.distance_to(look_at_pos) > 0.1:
			look_at(look_at_pos, Vector3.UP, true)
		
		if can_attack:
			attack_player()
			
	# --- JARAK KEJAR ---
	else:
		nav_agent.target_position = player.global_position
		
		if not nav_agent.is_navigation_finished():
			var next_path_pos = nav_agent.get_next_path_position()
			var direction = (next_path_pos - global_position).normalized()
			
			# Gunakan current_speed yang sudah diacak, bukan SPEED yang const
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
			
			if velocity.length() > 0.2:
				var look_dir = global_position + Vector3(velocity.x, 0, velocity.z)
				look_at(look_dir, Vector3.UP, true)
				
				if can_attack: 
					# Gunakan animasi gerakan yang sudah diacak
					anim_player.play(move_anim)

	move_and_slide()

# --- FUNGSI MENYERANG ---
func attack_player():
	can_attack = false
	# Gunakan animasi serangan yang sudah diacak
	anim_player.play(attack_anim) 
	
	if player.has_method("take_damage"):
		player.take_damage(10) 
		
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

# --- FUNGSI MENERIMA DAMAGE ---
func take_damage(damage_amount):
	if is_dead:
		return 
		
	health -= damage_amount
	
	if health <= 0:
		die()
	else:
		# Logika Reaksi HitReact akan menghentikan gerakan lari
		is_hit = true
		velocity = Vector3.ZERO 
		anim_player.play("HitReact") 
		await anim_player.animation_finished 
		is_hit = false 

# --- FUNGSI MATI ---
func die():
	is_dead = true 
	$CollisionShape3D.disabled = true 
	anim_player.play("Death")
	
	var spawner = get_tree().current_scene.find_child("ZombieSpawner", true, false)
	if spawner and spawner.has_method("on_zombie_killed"):
		spawner.on_zombie_killed()
	
	await anim_player.animation_finished 
	queue_free()
