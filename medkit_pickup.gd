extends Area3D

var heal_amount: int = 40
var float_speed: float = 3.0
var float_height: float = 0.3
var time_passed: float = 0.0
var start_y: float = 0.0

# Sinyal khusus untuk memberitahu Altar bahwa Medkit ini sudah diambil
signal medkit_taken

func _ready():
	start_y = position.y
	body_entered.connect(_on_body_entered)

func _process(delta):
	# Animasi berputar dan mengambang
	rotate_y(deg_to_rad(90) * delta)
	time_passed += delta
	position.y = start_y + (sin(time_passed * float_speed) * float_height)

func _on_body_entered(body):
	if body.name == "Player_Lis":
		# Cek apakah player punya fungsi heal DAN darahnya belum penuh
		if body.has_method("heal") and body.health < body.max_health:
			body.heal(heal_amount)
			medkit_taken.emit() # Lapor ke Altar!
			queue_free() # Hancurkan medkit
