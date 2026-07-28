extends Node2D

# Khai báo các biến cơ bản cho Game Phòng thủ
var player_gold: int = 100
var castle_health: int = 200
var wave_timer: float = 0.0
var wave_interval: float = 100.0
var current_wave: int = 0
@export var monster_scene: PackedScene

var wave_data: Array = []
var is_spawning_wave: bool = false
var spawn_queue: Array = []
var spawn_delay: float = 1.0
var spawn_cooldown: float = 0.0
func _ready() -> void:
	wave_interval = Global.wave_interval
	print("--- GAME PHÒNG THỦ BẮT ĐẦU --- | Wave Timer: ", wave_interval, "s")
	_load_wave_data() # Đọc file JSON lúc khởi động
		
func _on_game_over() -> void:
	print("🛑 [MAIN] NHẬN LỆNH GAME OVER! Tạm dừng (Pause) toàn bộ Game!")
	get_tree().paused = true # Đóng băng toàn bộ hoạt động (quái, nông dân, tháp)
	
	# Code nhanh 1 bảng chữ GAME OVER ĐỎ chót giữa màn hình (Không cần vẽ UI tay)
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	var label = Label.new()
	label.text = "GAME OVER"
	label.add_theme_font_size_override("font_size", 80)
	label.add_theme_color_override("font_color", Color.RED)
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	canvas.add_child(label)
	add_child(canvas)
func _load_wave_data() -> void:
	if FileAccess.file_exists("res://waves.json"):
		var file = FileAccess.open("res://waves.json", FileAccess.READ)
		var json_string = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			wave_data = json.data
			print("📁 [HỆ THỐNG] Đã nạp thành công ", wave_data.size(), " Waves từ JSON.")
		else:
			print("🚨 [LỖI] Phân tích waves.json thất bại!")
	else:
		print("🚨 [LỖI] Không tìm thấy file res://waves.json!")

func _process(delta: float) -> void:
	# Xử lý đẩy quái ra từ từ nếu đang trong quá trình sinh
	if is_spawning_wave:
		spawn_cooldown -= delta
		if spawn_cooldown <= 0.0:
			_spawn_single_monster()
			spawn_cooldown = spawn_delay
	else:
		# Đếm ngược tới Wave tiếp theo
		wave_timer += delta
		if wave_timer >= wave_interval:
			wave_timer = 0.0
			current_wave += 1
			_start_monster_wave()

func _start_monster_wave() -> void:
	var data_index = min(current_wave - 1, wave_data.size() - 1)
	if data_index < 0: return 
	
	var current_wave_config = wave_data[data_index]
	spawn_delay = current_wave_config.get("delay_between", 1.0)
	var monsters_map = current_wave_config.get("monsters", {})
	
	spawn_queue.clear()
	
	# BẢN VÁ: Đọc Map cấu hình quái và nhét vào hàng chờ
	var total_count = 0
	for m_type_key in monsters_map.keys():
		var stats = monsters_map[m_type_key]
		var count = stats.get("count", 0)
		total_count += count
		
		for i in range(count):
			# Lưu cả tên loại quái và bộ chỉ số của nó vào hàng chờ
			spawn_queue.append({"type_name": m_type_key, "stats": stats})
	
	# Đảo trộn mảng để quái ra xen kẽ nhau cho tự nhiên
	spawn_queue.shuffle()
	
	is_spawning_wave = true
	spawn_cooldown = 0.0
	
	Global.log_event.emit("alert", "WAVE " + str(current_wave) + " BẮT ĐẦU: " + str(total_count) + " Quái vật đang tới!")
	# BẰNG CHỨNG LOG:
	print("☠️ [WAVE ", current_wave, "] Đã nạp ", total_count, " quái vật vào hàng chờ.")
func _spawn_single_monster() -> void:
	if spawn_queue.size() == 0:
		is_spawning_wave = false
		print("✅ [WAVE ", current_wave, "] Đã sinh xong toàn bộ quái vật.")
		return
		
	# Lấy con quái tiếp theo ra (Bao gồm type_name và stats)
	var next_monster_data = spawn_queue.pop_front() 
	
	if monster_scene:
		var monster = monster_scene.instantiate()
		var corners = [
			Vector2(-1000, -1000), Vector2(1000, -1000),
			Vector2(-1000, 1000), Vector2(1000, 1000)
		]
		monster.global_position = corners[randi() % corners.size()]
		
		# BẢN VÁ: Truyền cục dữ liệu cấu hình sang cho quái vật tự xử lý
		get_parent().add_child(monster)
		monster.setup(next_monster_data["type_name"], next_monster_data["stats"])
		
		print("🦇 [SPAWN] Đã sinh 1 quái [", next_monster_data["type_name"], "]. Còn lại: ", spawn_queue.size())
