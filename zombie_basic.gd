extends CharacterBody3D

# --- STATISTIK ZOMBIE ---
const SPEED = 3
var health = 3 
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

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
var is_hit = false # Variabel baru untuk efek terhuyung saat ditembak

func _ready():
	player = get_tree().current_scene.find_child("Player_Lis", true, false)

func _physics_process(delta):
	# 1. Terapkan gravitasi selalu agar tidak melayang
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 2. Jika mati ATAU sedang terkena tembakan (terhuyung), zombie berhenti mengejar
	if is_dead or is_hit:
		move_and_slide() # Tetap panggil ini agar gravitasi bekerja
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
			
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
			
			if velocity.length() > 0.2:
				var look_dir = global_position + Vector3(velocity.x, 0, velocity.z)
				look_at(look_dir, Vector3.UP, true)
				
				# MAIN KAN ANIMASI JALAN
				if can_attack: 
					anim_player.play("Walk")

	move_and_slide()

# --- FUNGSI MENYERANG ---
func attack_player():
	can_attack = false
	anim_player.play("Punch") 
	
	# Kirim damage 10 ke Player
	if player.has_method("take_damage"):
		player.take_damage(10) 
		
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

# --- FUNGSI MENERIMA DAMAGE & ANIMASI HIT ---
func take_damage(damage_amount):
	if is_dead:
		return 
		
	health -= damage_amount
	print("Zombie kena tembak! Sisa HP: ", health)
	
	if health <= 0:
		die()
	else:
		# LOGIKA REAKSI TERKENA TEMBAKAN (STAGGER)
		is_hit = true
		velocity = Vector3.ZERO # Hentikan dorongan lari zombie secara instan
		anim_player.play("HitReact") # Putar animasi tersentak
		
		# Tunggu sampai animasi HitReact selesai diputar
		await anim_player.animation_finished 
		
		# Setelah animasi selesai, zombie kembali normal dan bisa mengejar
		is_hit = false 

# --- FUNGSI MATI ---
func die():
	is_dead = true 
	$CollisionShape3D.disabled = true 
	
	anim_player.play("Death")
	print("Zombie Mati! Menunggu animasi selesai...")
	
	await anim_player.animation_finished 
	queue_free()
