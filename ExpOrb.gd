extends Area3D

# Zombie akan mengubah nilai ini saat spawn (misal boss kasih 10)
var exp_value: int = 1 
var is_picked_up: bool = false

@onready var pickup_audio = $PickupAudio

func _ready():
	# Sambungkan sinyal sentuh secara otomatis lewat kode
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if is_picked_up: return
	
	if body.name == "Player_Lis":
		if body.has_method("add_exp"):
			is_picked_up = true
			body.add_exp(exp_value)
			
			# --- TRIK AUDIO PICKUP ---
			pickup_audio.pitch_scale = randf_range(0.9, 1.1)
			pickup_audio.play()
			
			hide()
			$CollisionShape3D.set_deferred("disabled", true)
			
			await pickup_audio.finished
			queue_free()
