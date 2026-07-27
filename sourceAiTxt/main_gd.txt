extends Node2D

# Khai báo các biến cơ bản cho Game Phòng thủ
var player_gold: int = 100
var castle_health: int = 200
var wave_timer: float = 0.0
var wave_interval: float = 100.0 # Tạm để 10 giây để test (Sau này đổi thành 180.0 = 3 phút)
var current_wave: int = 0
@export var monster_scene: PackedScene # Dùng để kéo thả file Quái vật vào sau này
func _ready() -> void:
	wave_interval = Global.wave_interval # Đọc thời gian quái từ Menu
	print("--- GAME PHÒNG THỦ BẮT ĐẦU --- | Wave Timer: ", wave_interval, "s")
	
	var bases = get_tree().get_nodes_in_group("main_base")
	if bases.size() > 0:
		# Kết nối đường dây nóng: Lắng nghe tín hiệu nhà sập
		bases[0].game_over.connect(_on_game_over)
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
func _process(delta: float) -> void:
	# Hệ thống đếm giờ sinh quái (Wave Timer)
	wave_timer += delta
	if wave_timer >= wave_interval:
		wave_timer = 0.0
		current_wave += 1
		_spawn_monster_wave()
# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE main.gd
func _spawn_monster_wave() -> void:
	#print("\n☠️ [WAVE ", current_wave, "] CẢNH BÁO! QUÁI VẬT ĐANG TRÀN VÀO TỪ 4 GÓC MAP!")
	if monster_scene == null:
		print("🚨 [LỖI MAIN] Chưa kéo file monster.tscn vào Inspector của Node Main!")
		return

	var corners = [
		Vector2(-1900, -1900), # Góc trên trái
		Vector2(1900, -1900),  # Góc trên phải
		Vector2(-1900, 1900),  # Góc dưới trái
		Vector2(1900, 1900)    # Góc dưới phải
	]
	
	var total_spawned = 0
	for corner in corners:
		# 1. Sinh 4 con Quái Nhanh (FAST - Type 0) ở góc này
		for i in range(4):
			var spawn_pos = corner + Vector2(randf_range(-40, 40), randf_range(-40, 40))
			var m = monster_scene.instantiate()
			m.global_position = spawn_pos
			add_child(m)
			if m.has_method("setup"): m.setup(0)
			total_spawned += 1
			
		# 2. Sinh 4 con Quái Trâu (TANK - Type 1) ở góc này
		for i in range(4):
			var spawn_pos = corner + Vector2(randf_range(-40, 40), randf_range(-40, 40))
			var m = monster_scene.instantiate()
			m.global_position = spawn_pos
			add_child(m)
			if m.has_method("setup"): m.setup(1)
			total_spawned += 1
			
	print("👹 [SPAWN HOÀN TẤT] Đã sinh tổng cộng ", total_spawned, " quái vật tràn về Nhà Chính!")
