extends CharacterBody3D

# --- STATISTIK ZOMBIE ARM2 (Tipe Cepat/Runner) ---
const SPEED = 3.0 # Lebih cepat dari zombie basic (2.5)
var health = 10
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# --- REFERENSI NODE ---
@onready var nav_agent = $NavigationAgent3D
@onready var anim_player = $AnimationPlayer 
@onready var indicator_arrow = $IndicatorArrow

var player: CharacterBody3D = null

# --- PENGATURAN SERANGAN ---
var attack_distance = 2.0
var can_attack = true
var attack_cooldown = 0.8 # Memukul jauh lebih cepat dari zombie lain!

# --- STATUS ZOMBIE ---
var is_dead = false 
var is_hit = false 

func _ready():
	player = get_tree().current_scene.find_child("Player_Lis", true, false)

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
			
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
			
			if velocity.length() > 0.2:
				var look_dir = global_position + Vector3(velocity.x, 0, velocity.z)
				look_at(look_dir, Vector3.UP, true)
				
				if can_attack: 
					# Jika model zombie ini punya animasi lari, kamu bisa ganti "Walk" jadi "Run"
					anim_player.play("Walk") 

	move_and_slide()

# --- FUNGSI MENYERANG ---
func attack_player():
	can_attack = false
	anim_player.play("Punch") 
	
	# Kirim damage 30 ke Player
	if player.has_method("take_damage"):
		player.take_damage(30) 
		
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

# --- FUNGSI MENERIMA DAMAGE ---
func take_damage(damage_amount):
	if is_dead:
		return 
		
	health -= damage_amount
	print("Zombie Arm2 kena tembak! Sisa HP: ", health)
	
	if health <= 0:
		die()
	else:
		is_hit = true
		velocity = Vector3.ZERO 
		anim_player.play("HitReact") 
		
		await anim_player.animation_finished 
		is_hit = false 

# --- FUNGSI MATI ---
func die():
	is_dead = true 
	$CollisionShape3D.disabled = true 
	
	if indicator_arrow:
		indicator_arrow.visible = false
	
	anim_player.play("Death")
	print("Zombie Arm2 Tumbang!")
	
	await anim_player.animation_finished 
	queue_free()
