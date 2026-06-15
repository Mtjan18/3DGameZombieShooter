extends Node3D

@onready var models = [$Blood_1, $Blood_2, $Blood_3]
var active_mesh: MeshInstance3D

func _ready():
	for m in models:
		m.hide()

	active_mesh = models.pick_random()
	active_mesh.show()

	rotation_degrees.y = randf_range(0, 360)

	fade_away()

func fade_away():

	var tween = create_tween()
	
	# Properti "transparency" pada node 3D: 0.0 = tebal, 1.0 = hilang
	tween.tween_property(active_mesh, "transparency", 1.0, 4.0)
	
	# Tunggu animasi selesai
	await tween.finished
	queue_free()
