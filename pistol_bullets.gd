extends Node3D

var speed = 50
var lifetime: float = 2
var damage = 1 # Jumlah HP yang dikurangi

func _process(delta: float) -> void:
	# Pergerakan peluru
	position += transform.basis * Vector3(0, 0, -speed) * delta
	
	# Hancurkan peluru jika sudah melesat terlalu lama (lifetime)
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

# --- FUNGSI DETEKSI TABRAKAN (Hasil Connect Signal) ---
# Nama fungsi ini mungkin sedikit berbeda (contoh: _on_area_3d_body_entered), 
# pastikan sama persis dengan yang dibuat otomatis oleh Godot di script-mu.
func _on_area_3d_body_entered(body: Node3D) -> void:
	# 1. Cek apakah yang ditabrak adalah Zombie
	if body.is_in_group("Enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
			
	# 2. HANCURKAN PELURU SEKETIKA
	# Posisinya di luar 'if' agar menabrak tembok atau zombie, peluru langsung hilang!
	queue_free()
