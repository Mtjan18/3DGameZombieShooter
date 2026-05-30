extends Camera3D

@export var player: CharacterBody3D 

# Jarak konstan kamera dari player (sesuaikan dengan posisi di langkah 2)
var offset: Vector3 = Vector3(0, 15, 8) 

func _ready():
	if player:
		# Menghitung offset awal berdasarkan posisi kamera saat ini
		offset = global_position - player.global_position

func _physics_process(delta):
	if player:
		# Kamera mengikuti posisi player + mempertahankan jarak offset
		# Menggunakan lerp agar pergerakan kamera terasa smooth/halus
		var target_pos = player.global_position + offset
		global_position = global_position.lerp(target_pos, delta * 5.0)
