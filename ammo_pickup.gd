extends Area3D

var weapon_type: String = "Pistol"
var ammo_amount: int = 10

var float_speed: float = 3.0
var float_height: float = 0.3
var time_passed: float = 0.0
var start_y: float = 0.0

var is_picked_up: bool = false

@onready var mesh = $Pickup_Bullets
@onready var pickup_audio = $PickupAudio

var lifespan: float = 15.0 

func _ready():
	start_y = global_position.y
	
	var mat = mesh.get_active_material(0).duplicate()
	mesh.set_surface_override_material(0, mat)
	
	if randf() > 0.5:
		weapon_type = "Pistol"
		ammo_amount = 10
		mat.set_shader_parameter("base_color", Color(1.0, 0.8, 0.0)) 
	else:
		weapon_type = "Rifle"
		ammo_amount = 20
		mat.set_shader_parameter("base_color", Color(0.0, 0.6, 1.0)) 
		
	body_entered.connect(_on_body_entered)
	start_despawn_timer()

func _process(delta):
	if is_picked_up: return
	
	rotate_y(deg_to_rad(90) * delta)
	time_passed += delta
	global_position.y = start_y + (sin(time_passed * float_speed) * float_height)

func _on_body_entered(body):
	if is_picked_up: return
	
	if body.name == "Player_Lis":
		if body.has_method("add_ammo"):
			is_picked_up = true
			body.add_ammo(weapon_type, ammo_amount)
			
			# --- TRIK AUDIO PICKUP ---
			pickup_audio.pitch_scale = randf_range(0.9, 1.1)
			pickup_audio.play()
			
			hide()
			$CollisionShape3D.set_deferred("disabled", true)
			
			await pickup_audio.finished
			queue_free()

func start_despawn_timer():
	await get_tree().create_timer(lifespan - 3.0).timeout
	
	for i in range(6): 
		if not is_instance_valid(self) or is_picked_up: return 
		
		mesh.visible = not mesh.visible
		await get_tree().create_timer(0.5).timeout
		
	if is_instance_valid(self) and not is_picked_up:
		queue_free()
