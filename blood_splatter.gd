extends Node3D

@onready var models = [$Blood_1, $Blood_2, $Blood_3] # Masukkan node modelmu ke sini
var active_mesh: MeshInstance3D

func _ready():
	# 1. Sembunyikan semua model terlebih dahulu
	for m in models:
		m.hide()
		
	# 2. Pilih 1 model secara acak untuk ditampilkan
	active_mesh = models.pick_random()
	active_mesh.show()
	
	# 3. Putar rotasi Y secara acak (0-360 derajat) agar jejaknya tidak monoton
	rotation_degrees.y = randf_range(0, 360)
	
	# 4. Mulai proses hilangnya darah
	fade_away()

func fade_away():
	# Biarkan jejak darah menempel di lantai selama 15 detik
	#await get_tree().create_timer(4.0).timeout
	
	# Memudar perlahan selama 4 detik menggunakan Tween Godot 4
	var tween = create_tween()
	
	# Properti "transparency" pada node 3D: 0.0 = tebal, 1.0 = hilang
	tween.tween_property(active_mesh, "transparency", 1.0, 4.0)
	
	# Tunggu animasinya selesai memudar, lalu hancurkan!
	await tween.finished
	queue_free()
