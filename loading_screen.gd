extends CanvasLayer

@onready var progress_bar = $ProgressBar
var target_scene_path = ""
var progress = []

func _ready():
	hide()
	set_process(false)
	# Memastikan loading screen kebal dari efek "Pause"
	process_mode = Node.PROCESS_MODE_ALWAYS 

func load_scene(path: String):
	target_scene_path = path
	
	# Cek apakah file benar-benar ada!
	if not ResourceLoader.exists(target_scene_path):
		print("ERROR FATAL: Nama file/path salah atau tidak ditemukan -> ", target_scene_path)
		hide() 
		return
		
	show()
	progress_bar.value = 0.0
	
	var request = ResourceLoader.load_threaded_request(target_scene_path)
	if request != OK:
		print("ERROR: Gagal memulai proses loading untuk -> ", target_scene_path)
		hide()
		return
		
	set_process(true)

func _process(_delta):
	var loading_status = ResourceLoader.load_threaded_get_status(target_scene_path, progress)
	
	if loading_status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		progress_bar.value = progress[0] * 100.0
		
	elif loading_status == ResourceLoader.THREAD_LOAD_LOADED:
		set_process(false)
		progress_bar.value = 100.0
		
		var new_scene = ResourceLoader.load_threaded_get(target_scene_path)
		get_tree().change_scene_to_packed(new_scene)
		
		hide()
		target_scene_path = ""
		
	# Jika sistem Godot gagal memuat map
	elif loading_status == ResourceLoader.THREAD_LOAD_FAILED or loading_status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		print("ERROR: Proses loading gagal di tengah jalan!")
		set_process(false)
		hide()
