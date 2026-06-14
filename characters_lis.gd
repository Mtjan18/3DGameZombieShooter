extends CharacterBody3D

var SPEED: float = 5.0
var max_health: int = 100
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
var is_reloading: bool = false

# --- VARIABEL AUDIO FOOTSTEP ---
@onready var footstep_audio = $FootstepAudio
var footstep_timer: float = 0.0
var footstep_interval: float = 0.35 

# --- VARIABEL AUDIO TEMBAKAN, HIT, RELOAD & BGM ---
@onready var shoot_audio = $ShootAudio
@onready var hit_audio = $HitAudio 
@onready var reload_audio = $ReloadAudio 
@onready var gameplay_bgm = $GameplayBGM # <--- Variabel BGM

# --- POSISI VARIABEL SENJATA HARUS DI SINI (PALING ATAS) ---
@onready var weapon_meshes = {
	"Pistol": $CharacterArmature/Skeleton3D/Middle1_L/Pistol,
	"Rifle": $CharacterArmature/Skeleton3D/Middle1_L/Rifle
}

var weapons_data = [
	{"name": "Pistol", "type": "ranged", "fire_rate": 0.5, "ammo": 15, "reserve": 30, "max_ammo": 15, "max_reserve": 60},
	{"name": "Rifle", "type": "ranged", "fire_rate": 0.1, "ammo": 30, "reserve": 90, "max_ammo": 30, "max_reserve": 180}
]

var current_weapon_index = 0

func _ready():
	for wep in weapon_meshes.values():
		wep.visible = false
		
	call_deferred("update_exp_ui") 
	call_deferred("switch_weapon", 0)
	
	# Mulai putar musik latar saat game dimulai!
	gameplay_bgm.play()

func _physics_process(delta):
	if is_dead:
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y -= gravity * delta

	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		playback.travel("Run_Gun") 
		
		if is_on_floor():
			footstep_timer -= delta
			if footstep_timer <= 0.0:
				footstep_audio.pitch_scale = randf_range(0.85, 1.15)
				footstep_audio.play()
				footstep_timer = footstep_interval
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		playback.travel("Idle_Gun") 
		footstep_timer = 0.0

	move_and_slide()
	look_at_mouse()
	
	if Input.is_action_just_pressed("reload"):
		reload_weapon()
	
	if shoot_timer > 0.0:
		shoot_timer -= delta
		
	if Input.is_action_pressed("click") and shoot_timer <= 0 and not is_reloading:
		var current_weapon = weapons_data[current_weapon_index]
		
		if current_weapon["type"] == "ranged":
			if current_weapon["ammo"] > 0: 
				current_weapon["ammo"] -= 1 
				update_hud() 
				
				shoot_audio.pitch_scale = randf_range(0.9, 1.1) 
				shoot_audio.play()
				
				var instance = bullet.instantiate()
				get_parent().add_child(instance)
				instance.global_position = spawn.global_position
				
				if mouse_target != Vector3.ZERO:
					instance.look_at(mouse_target, Vector3.UP)
				else:
					instance.global_transform.basis = spawn.global_transform.basis
					
				shoot_timer = current_fire_rate
				
				if current_weapon["ammo"] <= 0:
					reload_weapon()

func look_at_mouse():
	var camera = get_viewport().get_camera_3d()
	var mouse_pos = get_viewport().get_mouse_position()

	var drop_plane = Plane(Vector3.UP, spawn.global_position.y)
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_dir = camera.project_ray_normal(mouse_pos)
	var intersection = drop_plane.intersects_ray(ray_origin, ray_dir)

	if intersection != null:
		mouse_target = intersection
		var look_pos = intersection
		look_pos.y = global_position.y 
		look_at(look_pos, Vector3.UP)

func play_hit_animation():
	if playback:
		playback.travel("HitReact") 

# --- FUNGSI MENGALAMI DAMAGE & AUDIO HIT ---
func take_damage(amount):
	if is_dead:
		return
		
	health -= amount
	if health < 0: health = 0
	
	hit_audio.pitch_scale = randf_range(0.9, 1.1)
	hit_audio.play()
	
	var ui = get_tree().root.find_child("UIManager", true, false)
	if ui and ui.has_method("update_health"):
		ui.update_health(health)
		
	if health <= 0:
		die()
	else:
		play_hit_animation() 

func heal(amount: int):
	if is_dead: return
	
	health += amount
	if health > max_health:
		health = max_health 
		
	var ui = get_tree().root.find_child("UIManager", true, false)
	if ui and ui.has_method("update_health"):
		ui.update_health(health)
		
	print("Healed! HP sekarang: ", health)

func die():
	is_dead = true
	velocity = Vector3.ZERO 
	
	# Hentikan BGM seketika saat player mati
	gameplay_bgm.stop()
	
	if playback:
		playback.travel("Death") 
		
	var ui = get_tree().root.find_child("UIManager", true, false)
	if ui and ui.has_method("show_game_over"):
		ui.show_game_over()

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
	
	# Membatalkan efek audio reload jika player mengganti senjata saat sedang reload
	if is_reloading:
		reload_audio.stop()
		
	is_reloading = false
	
	update_hud()

func update_hud():
	var ui = get_tree().current_scene.find_child("UIManager", true, false)
	if ui:
		var wep = weapons_data[current_weapon_index]
		
		if ui.has_method("update_weapon_hud"):
			ui.update_weapon_hud(wep["name"], wep["ammo"], wep["reserve"])
			
		if ui.has_method("setup_cursor_ammo"):
			ui.setup_cursor_ammo(wep["max_ammo"])
			if not is_reloading:
				ui.update_cursor_ammo(wep["ammo"])

func reload_weapon():
	if is_reloading: 
		return 
		
	var current_weapon = weapons_data[current_weapon_index]
	
	if current_weapon["type"] == "ranged":
		if current_weapon["ammo"] < current_weapon["max_ammo"] and current_weapon["reserve"] > 0:
			
			is_reloading = true 
			
			# --- MAINKAN AUDIO RELOAD ---
			reload_audio.pitch_scale = 1.0 # Pastikan nada normal
			reload_audio.play()
			
			var reload_duration = 3.0 
			var ammo_needed = current_weapon["max_ammo"] - current_weapon["ammo"]
			
			var ammo_to_add = 0
			if current_weapon["reserve"] >= ammo_needed:
				ammo_to_add = ammo_needed
			else:
				ammo_to_add = current_weapon["reserve"]
				
			var ui = get_tree().current_scene.find_child("UIManager", true, false)
			if ui and ui.has_method("animate_reload_cursor"):
				ui.animate_reload_cursor(reload_duration, current_weapon["ammo"] + ammo_to_add)
			
			var weapon_name_before_reload = current_weapon["name"]
			
			await get_tree().create_timer(reload_duration).timeout
			
			if not is_dead and weapons_data[current_weapon_index]["name"] == weapon_name_before_reload:
				weapons_data[current_weapon_index]["ammo"] += ammo_to_add
				weapons_data[current_weapon_index]["reserve"] -= ammo_to_add
				is_reloading = false 
				update_hud() 
			else:
				is_reloading = false
				update_hud()

func add_ammo(received_weapon_name: String, amount: int):
	for wep in weapons_data:
		if wep["name"] == received_weapon_name:
			wep["reserve"] = min(wep["reserve"] + amount, wep["max_reserve"])
			
			if weapons_data[current_weapon_index]["name"] == received_weapon_name:
				update_hud()
			
			break

var current_level: int = 1
var current_exp: int = 0
var exp_to_next_level: int = 15

func add_exp(amount: int):
	current_exp += amount
	while current_exp >= exp_to_next_level:
		level_up()
		
	update_exp_ui()

func level_up():
	current_level += 1
	current_exp -= exp_to_next_level 
	
	exp_to_next_level = int(15.0 * pow(current_level, 1.2)) 
	
	var ui = get_tree().current_scene.find_child("UIManager", true, false)
	if ui and ui.has_method("update_level_text"):
		ui.update_level_text(current_level)
		
	var upgrade_panel = get_tree().current_scene.find_child("UpgradeUI", true, false)
	if upgrade_panel and upgrade_panel.has_method("trigger_level_up"):
		upgrade_panel.trigger_level_up()

func update_exp_ui():
	var ui = get_tree().current_scene.find_child("UIManager", true, false)
	if ui and ui.has_method("update_exp_bar"):
		ui.update_exp_bar(current_exp, exp_to_next_level)
