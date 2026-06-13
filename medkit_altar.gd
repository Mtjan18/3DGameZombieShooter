extends Node3D

@export var medkit_scene: PackedScene 
@onready var indicator_arrow = $IndicatorArrow # Pastikan node panahmu ada

var respawn_time: float = 60.0 
var is_medkit_available: bool = false
var player: CharacterBody3D = null

func _ready():
	# Sembunyikan panah di awal
	if indicator_arrow: indicator_arrow.hide()
	
	player = get_tree().current_scene.find_child("Player_Lis", true, false)
	call_deferred("spawn_medkit")

func _process(_delta):
	# Jika tidak ada player atau panah, jangan lakukan apa-apa
	if player == null or indicator_arrow == null: return
	
	# Hitung persentase darah player
	var hp_percentage = float(player.health) / float(player.max_health)
	
	# Panah HANYA muncul jika: Darah <= 30% DAN Medkit belum diambil
	if hp_percentage <= 0.3 and is_medkit_available:
		indicator_arrow.show()
		
		# 1. Cari arah dari Player menunjuk ke Altar ini
		var dir_to_altar = (global_position - player.global_position).normalized()
		
		# 2. Posisikan panah melayang di dekat player (jarak 1.5 meter)
		indicator_arrow.global_position = player.global_position + (dir_to_altar * 1.5)
		
		# 3. Kunci ketinggian panah di lantai atau sedikit melayang (sesuaikan angkanya)
		indicator_arrow.global_position.y = player.global_position.y + 0.2 
		
		# 4. Suruh panah menatap ke arah Altar
		var target_look = Vector3(global_position.x, indicator_arrow.global_position.y, global_position.z)
		indicator_arrow.look_at(target_look, Vector3.UP)
	else:
		indicator_arrow.hide()

func spawn_medkit():
	if is_medkit_available or medkit_scene == null: return
	
	var medkit = medkit_scene.instantiate()
	medkit.position = Vector3(0, 1.0, 0)
	add_child(medkit)
	
	medkit.medkit_taken.connect(_on_medkit_taken)
	is_medkit_available = true

func _on_medkit_taken():
	is_medkit_available = false
	print("Medkit diambil! Menunggu respawn...")
	
	await get_tree().create_timer(respawn_time).timeout
	spawn_medkit()
