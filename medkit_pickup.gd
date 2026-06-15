extends Area3D

var heal_amount: int = 40
var float_speed: float = 3.0
var float_height: float = 0.3
var time_passed: float = 0.0
var start_y: float = 0.0

# Mencegah item diambil 2 kali
var is_picked_up: bool = false

@onready var pickup_audio = $PickupAudio

signal medkit_taken

func _ready():
	start_y = position.y
	body_entered.connect(_on_body_entered)

func _process(delta):
	# Jika sudah diambil, hentikan animasi 
	if is_picked_up: return 
	
	rotate_y(deg_to_rad(90) * delta)
	time_passed += delta
	position.y = start_y + (sin(time_passed * float_speed) * float_height)

func _on_body_entered(body):
	if is_picked_up: return
	
	if body.name == "Player_Lis":
		if body.has_method("heal") and body.health < body.max_health:
			is_picked_up = true
			body.heal(heal_amount)
			medkit_taken.emit() 
			
			# Audio pickup
			pickup_audio.pitch_scale = randf_range(0.9, 1.1)
			pickup_audio.play()
			
			hide()
			$CollisionShape3D.set_deferred("disabled", true) 
			
			await pickup_audio.finished # Tunggu suara selesai
			queue_free()
