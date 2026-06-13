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
@onready var indicator_arrow = $IndicatorArrow

var player: CharacterBody3D = null

# --- PENGATURAN SERANGAN ---
var attack_distance = 2.0
var can_attack = true
var attack_cooldown = 1.5

# --- STATUS ZOMBIE ---
var is_dead = false 
var is_hit = false 

@export var ammo_scene: PackedScene
@export var exp_orb_scene: PackedScene
@export var blood_scene: PackedScene
var ammo_drop_chance: float = 0.4 

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
		current_speed = 2.5
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

# --- FITUR PANAH INDIKATOR (1 Meter dari Player) ---
	if indicator_arrow:
		# 1. Cari arah dari Player menuju Zombie ini
		var dir_to_zombie = (global_position - player.global_position).normalized()
		
		# 2. Taruh panah di radius 1.2 meter dari Player (agar tidak nabrak badan)
		indicator_arrow.global_position = player.global_position + (dir_to_zombie * 1.2)
		
		# 3. Kunci ketinggian panah setinggi dada player (biar ga nempel di aspal)
		indicator_arrow.global_position.y = player.global_position.y + 1.0
		
		# 4. Suruh panah menatap ke arah zombie
		# (Karena Y dilock, kita arahkan target tatapannya ke tinggi yang sama agar panah tidak mendongak)
		var target_look = Vector3(global_position.x, indicator_arrow.global_position.y, global_position.z)
		indicator_arrow.look_at(target_look, Vector3.UP)
		
		# 5. [ANTI VISUAL CLUTTER] Sembunyikan panah jika zombie sudah dekat (misal jarak 10 meter)
		if distance_to_player < 10.0:
			indicator_arrow.visible = false
		else:
			indicator_arrow.visible = true
			
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
	if is_dead: return 
	is_dead = true 
	$CollisionShape3D.set_deferred("disabled", true) 
	
	if indicator_arrow: indicator_arrow.visible = false
	anim_player.play("Death")
	
	if randf() <= ammo_drop_chance: 
		var ammo_instance = ammo_scene.instantiate()
		ammo_instance.position = self.position + Vector3(0, 0.5, 0)
		get_parent().call_deferred("add_child", ammo_instance)
	
	var orb = exp_orb_scene.instantiate()
	orb.exp_value = 3 # Chubby Kasih 3 EXP (Hijau)
	orb.position = self.position + Vector3(0, 0.5, 0)
	get_parent().call_deferred("add_child", orb)
	
	var ui = get_tree().root.find_child("UIManager", true, false)
	if ui and ui.has_method("add_score"): ui.add_score(1)
		
	var spawner = get_tree().current_scene.find_child("ZombieSpawner", true, false)
	if spawner and spawner.has_method("on_zombie_killed"): spawner.on_zombie_killed()
	
	var blood = blood_scene.instantiate()
	blood.global_position = Vector3(global_position.x, global_position.y + 0.05, global_position.z) 
	get_tree().current_scene.call_deferred("add_child", blood)
	
	await anim_player.animation_finished 
	queue_free()
