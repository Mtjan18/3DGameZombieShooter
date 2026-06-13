extends CanvasLayer

# --- DATABASE UPGRADE BERDASARKAN GDD ---
var upgrade_db = [
	{"id": "swift_feet", "name": "Swift Feet", "max_level": 3, "desc": "+10% Movement Speed"},
	{"id": "super_magnet", "name": "Super Magnet", "max_level": 3, "desc": "+1.5m Vacuum Radius"},
	{"id": "deep_pockets", "name": "Deep Pockets", "max_level": 5, "desc": "+30% Max Reserve Ammo"},
	{"id": "tough_skin", "name": "Tough Skin", "max_level": 4, "desc": "+25 Max HP & Full Heal"},
	{"id": "trigger_happy", "name": "Trigger Happy", "max_level": 4, "desc": "-10% Fire Rate Delay"}
]

# Menyimpan memori level upgrade yang sudah diambil pemain
var active_upgrades = {} 
var current_choices = [] 

@onready var cards = [
	$CenterContainer/VBoxContainer/MarginContainer/HBoxContainer/Card1,
	$CenterContainer/VBoxContainer/MarginContainer/HBoxContainer/Card2,
	$CenterContainer/VBoxContainer/MarginContainer/HBoxContainer/Card3
]

func _ready():
	hide() # Sembunyikan UI saat game baru mulai
	
	# Hubungkan klik tombol ke fungsi pilihan menggunakan fitur Lambda Godot 4
	for i in range(cards.size()):
		cards[i].pressed.connect(func(): _on_card_selected(i))

# --- FUNGSI MUNCULKAN PANEL (DIPANGGIL SAAT LEVEL UP) ---
func trigger_level_up():
	get_tree().paused = true # HENTIKAN WAKTU!
	show()
	
	# 1. Saring upgrade yang belum mentok (Max Level)
	var pool = []
	for upg in upgrade_db:
		var lvl = active_upgrades.get(upg.id, 0)
		if lvl < upg.max_level:
			pool.append(upg)
			
	# 2. Acak urutannya
	pool.shuffle()
	
	# 3. Ambil 3 teratas
	current_choices = pool.slice(0, 3)
	
	# 4. Tampilkan ke kartu
	for i in range(3):
		if i < current_choices.size():
			var choice = current_choices[i]
			var next_lvl = active_upgrades.get(choice.id, 0) + 1
			
			# Format Teks: Nama Level \n \n Deskripsi
			cards[i].text = choice.name + " Lv." + str(next_lvl) + "\n\n" + choice.desc
			cards[i].show()
		else:
			# Jika sisa upgrade di database kurang dari 3, sembunyikan kartu yang kosong
			cards[i].hide()

# --- FUNGSI SAAT KARTU DIKLIK ---
func _on_card_selected(index: int):
	var selected = current_choices[index]
	var id = selected.id
	
	# Naikkan level di memori
	active_upgrades[id] = active_upgrades.get(id, 0) + 1
	
	# Terapkan efek ke Player
	apply_to_player(id)
	
	# Lanjutkan permainan
	hide()
	get_tree().paused = false

# --- LOGIKA INJEKSI STATUS KE PLAYER ---
func apply_to_player(id: String):
	var player = get_tree().current_scene.find_child("Player_Lis", true, false)
	if not player: return
	
	match id:
		"swift_feet":
			player.SPEED += (player.SPEED * 0.10) # Tambah 10% [cite: 47]
			
		"super_magnet":
			# Kita akan modifikasi radius vacuum di script exp_orb nanti, 
			# untuk sementara kita simpan datanya di player
			if not player.has_meta("magnet_bonus"): player.set_meta("magnet_bonus", 0.0)
			player.set_meta("magnet_bonus", player.get_meta("magnet_bonus") + 1.5)
			
		"deep_pockets":
			for wep in player.weapons_data:
				if wep.has("max_reserve") and wep["max_reserve"] > 0:
					wep["max_reserve"] += int(wep["max_reserve"] * 0.30) # Tambah 30% [cite: 55]
					
		"tough_skin":
			player.max_health += 25 # Tambah batas HP [cite: 60]
			player.health += 25     # Tambah darah saat ini [cite: 59]
			player.take_damage(0)   # Trik memanggil fungsi update UI darah tanpa melukai player
			
		"trigger_happy":
			for wep in player.weapons_data:
				if wep["type"] == "ranged":
					wep["fire_rate"] *= 0.90 # Kurangi jeda 10% (makin kecil makin cepat) [cite: 71]
			# Perbarui kecepatan tembak senjata yang sedang dipegang
			player.current_fire_rate = player.weapons_data[player.current_weapon_index]["fire_rate"]
