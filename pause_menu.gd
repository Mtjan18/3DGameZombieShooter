extends CanvasLayer

@onready var val_hp = $CenterContainer/MainPanel/Margin/VBox/StatsGrid/ValHP
@onready var val_speed = $CenterContainer/MainPanel/Margin/VBox/StatsGrid/ValSpeed
@onready var val_fire_rate = $CenterContainer/MainPanel/Margin/VBox/StatsGrid/ValFireRate
@onready var upgrades_list = $CenterContainer/MainPanel/Margin/VBox/ScrollContainer/UpgradesList

@onready var btn_resume = $CenterContainer/MainPanel/Margin/VBox/ButtonsHBox/ResumeBtn
@onready var btn_retry = $CenterContainer/MainPanel/Margin/VBox/ButtonsHBox/RetryBtn
@onready var btn_menu = $CenterContainer/MainPanel/Margin/VBox/ButtonsHBox/MenuBtn

func _ready():
	hide() # Sembunyikan saat game baru mulai
	
	btn_resume.pressed.connect(_on_resume_pressed)
	btn_retry.pressed.connect(_on_retry_pressed)
	btn_menu.pressed.connect(_on_menu_pressed)

# Mengecek tombol ESC (secara default di Godot terdaftar sebagai "ui_cancel")
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause_menu()

func toggle_pause_menu():
	# Jangan buka menu pause jika layar Game Over atau Layar Upgrade sedang aktif
	var upgrade_ui = get_tree().current_scene.find_child("UpgradeUI", true, false)
	if upgrade_ui and upgrade_ui.visible:
		return 
		
	if visible:
		# Jika menu sedang terbuka, maka tutup dan jalankan game
		hide()
		get_tree().paused = false
	else:
		# Jika menu tertutup, update semua teks stat, buka menu, dan pause game
		update_stats_display()
		show()
		get_tree().paused = true

func update_stats_display():
	var player = get_tree().current_scene.find_child("Player_Lis", true, false)
	if player:
		# Update Label Stat RPG
		val_hp.text = str(player.health) + " / " + str(player.max_health)
		
		# Membulatkan kecepatan ke 1 angka di belakang koma (contoh: 5.5)
		val_speed.text = str(snapped(player.SPEED, 0.1)) 
		
		var wep = player.weapons_data[player.current_weapon_index]
		if wep["type"] == "ranged":
			val_fire_rate.text = str(snapped(wep["fire_rate"], 0.01)) + " sec"
		else:
			val_fire_rate.text = "Melee"
			
	update_upgrades_list()

func update_upgrades_list():
	# Bersihkan daftar upgrade lama agar tidak menumpuk saat menu dibuka-tutup
	for child in upgrades_list.get_children():
		child.queue_free()
		
	var upgrade_ui = get_tree().current_scene.find_child("UpgradeUI", true, false)
	
	if upgrade_ui:
		var active = upgrade_ui.active_upgrades # Mengambil kamus data (contoh: {"swift_feet": 2})
		var db = upgrade_ui.upgrade_db # Mengambil database nama asli
		
		if active.is_empty():
			var empty_label = Label.new()
			empty_label.text = "- Belum ada upgrade -"
			empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			upgrades_list.add_child(empty_label)
		else:
			# Looping semua upgrade yang sudah dimiliki
			for upg_id in active.keys():
				var lvl = active[upg_id]
				var upg_name = ""
				
				# Cari nama kerennya di database berdasarkan ID
				for item in db:
					if item["id"] == upg_id:
						upg_name = item["name"]
						break
				
				# Buat label teks (contoh: "★ Swift Feet Lv.2")
				var lbl = Label.new()
				lbl.text = "★ " + upg_name + " Lv." + str(lvl)
				lbl.add_theme_font_size_override("font_size", 20)
				upgrades_list.add_child(lbl)

# --- FUNGSI TOMBOL ---
func _on_resume_pressed():
	toggle_pause_menu()

func _on_retry_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_pressed():
	get_tree().paused = false
	# Nanti ganti path ini dengan scene Menu Utamamu saat sudah dibuat
	# get_tree().change_scene_to_file("res://MainMenu.tscn")
	print("Kembali ke Main Menu (Scene belum dibuat)")
