extends Node2D

# Khai báo các biến cơ bản cho Game Phòng thủ
var player_gold: int = 100
var castle_health: int = 200
var wave_timer: float = 0.0
var wave_interval: float = 100.0
var current_wave: int = 0
@export var monster_scene: PackedScene
var monster_spawn_points: Array[Vector2] = []
var wave_data: Array = []
var is_spawning_wave: bool = false
var spawn_queue: Array = []
var spawn_delay: float = 1.0
var spawn_cooldown: float = 0.0
func _ready() -> void:
	wave_interval = Global.wave_interval
	print("--- GAME PHÒNG THỦ BẮT ĐẦU --- | Wave Timer: ", wave_interval, "s")
	_load_wave_data() # Đọc file JSON lúc khởi động
	_build_map_from_editor_data()
		
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
# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE main.gd
func _spawn_single_monster() -> void:
	if spawn_queue.size() == 0:
		is_spawning_wave = false
		print("✅ [WAVE ", current_wave, "] Đã sinh xong toàn bộ quái vật.")
		return
		
	var next_monster_data = spawn_queue.pop_front() 
	
	if monster_scene:
		var monster = monster_scene.instantiate()
		
		if monster_spawn_points.size() > 0:
			monster.global_position = monster_spawn_points[randi() % monster_spawn_points.size()]
		else:
			var corners = [
				Vector2(-1000, -1000), Vector2(1000, -1000),
				Vector2(-1000, 1000), Vector2(1000, 1000)
			]
			monster.global_position = corners[randi() % corners.size()]
		
		# BẢN VÁ LỖI 1: Bỏ get_parent() đi, thêm quái trực tiếp làm con của màn chơi hiện tại
		add_child(monster)
		monster.setup(next_monster_data["type_name"], next_monster_data["stats"])
		
		# BẰNG CHỨNG LOG: Xác minh cha của quái vật là ai và tọa độ là bao nhiêu
		print("🦇 [SPAWN] Quái [", next_monster_data["type_name"], "] sinh tại: ", monster.global_position, " | Trực thuộc Node: ", monster.get_parent().name)
func _build_map_from_editor_data() -> void:
	if Global.get("current_map_to_play") == null or Global.current_map_to_play == "":
		print("⚠️ [MAIN] Không có map được chọn. Sử dụng map mặc định.")
		return
		
	var map_data = MapDataHandler.load_map(Global.current_map_to_play)
	if map_data.is_empty(): return
	
	print("🗺️ [MAIN] Đang dựng địa hình từ dữ liệu: ", Global.current_map_to_play)
	
	var grids = get_tree().get_nodes_in_group("grid_manager")
	if grids.size() > 0 and grids[0].has_method("setup_map_size"):
		var w = map_data.get("map_width", 2000)
		var h = map_data.get("map_height", 2000)
		grids[0].setup_map_size(w, h)
	
	for node_name in ["base", "GoldNode", "WoodNode"]:
		var old_node = get_node_or_null(node_name)
		if old_node: old_node.queue_free()
		
	var base_scene = load("res://scenes/base.tscn")
	var gold_scene = load("res://scenes/gold_node.tscn")
	var wood_scene = load("res://scenes/wood_node.tscn")
	
	if map_data.has("bases"):
		for b in map_data["bases"]:
			var base_inst = base_scene.instantiate()
			base_inst.global_position = Vector2(b.x, b.y)
			add_child(base_inst)
			
	if map_data.has("resources"):
		for r in map_data["resources"]:
			var res_inst = gold_scene.instantiate() if r.type == "gold" else wood_scene.instantiate()
			res_inst.global_position = Vector2(r.x, r.y)
			add_child(res_inst)
			
	# BẢN VÁ: Nạp danh sách điểm sinh quái từ file JSON
	monster_spawn_points.clear()
	if map_data.has("spawns") and map_data["spawns"].size() > 0:
		for s in map_data["spawns"]:
			var pt = Vector2(s.x, s.y)
			monster_spawn_points.append(pt)
			print("📍 [MAIN] Đã nạp điểm sinh quái tại: ", pt)
	var obstacle_scene = load("res://scenes/obstacle.tscn")
	if map_data.has("obstacles") and obstacle_scene != null:
		for obs in map_data["obstacles"]:
			var obs_inst = obstacle_scene.instantiate()
			obs_inst.global_position = Vector2(obs.x, obs.y)
			add_child(obs_inst)
			# BẰNG CHỨNG LOG: Xác minh đá được sinh ra
			print("🪨 [MAIN] Sinh Đá/Vật cản tại: ", obs_inst.global_position)
	if map_data.has("hero") and map_data["hero"].size() > 0:
		var hero_node = get_node_or_null("Hero")
		if hero_node:
			hero_node.global_position = Vector2(map_data["hero"][0].x, map_data["hero"][0].y)
			print("🦸 [MAIN] Đã dịch chuyển Hero đến vị trí chuẩn: ", hero_node.global_position)
