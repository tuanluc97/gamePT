extends StaticBody2D

signal gold_changed(new_amount: int)
signal wood_changed(new_amount: int)
signal game_over
# THÊM CÁC BIẾN NÀY LÊN ĐẦU FILE base.gd (Khu vực khai báo biến)
var spawn_queue: int = 0
var spawn_timer: Timer
var ui_layer: CanvasLayer
var buy_button: Button
var gold_storage: int = 0
var wood_storage: int = 0
var current_hp: float = 200.0

@export var worker_scene: PackedScene
# THAY THẾ HOẶC THÊM HÀM NÀY VÀO FILE base.gd
func _ready() -> void:
	# 1. Bật tính năng nhận Click chuột cho Nhà Chính
	input_pickable = true
	
	# 2. Tạo Timer đếm 3s sinh Kiến
	spawn_timer = Timer.new()
	spawn_timer.wait_time = 3.0
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_on_spawn_timeout)
	add_child(spawn_timer)
	
	# 3. Tạo Giao diện Nút Mua Kiến bằng Code (Hiện ở góc dưới trái)
	ui_layer = CanvasLayer.new()
	buy_button = Button.new()
	buy_button.text = "Mua Nông Dân (10 Vàng) - Hàng chờ: 0"
	buy_button.position = Vector2(20, 200) # Đặt dưới HUD
	buy_button.add_theme_font_size_override("font_size", 20)
	buy_button.pressed.connect(_on_buy_pressed)
	ui_layer.add_child(buy_button)
	add_child(ui_layer)
	ui_layer.visible = false # Ẩn đi, khi click vào nhà chính mới hiện
	
	# 4. Cấp 50 Vàng khởi đầu (Đợi 0.1s để HUD kịp load xong)
	await get_tree().create_timer(0.1).timeout
	add_resource("gold", 50)
	
# THÊM 4 HÀM NÀY VÀO CUỐI FILE base.gd

# Hàm bắt sự kiện Click chuột vào Nhà Chính
func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		ui_layer.visible = !ui_layer.visible # Bật/tắt Bảng mua
		print("🏰 [NHÀ CHÍNH] Đã click vào nhà! Trạng thái Menu Mua: ", ui_layer.visible)

func _on_buy_pressed() -> void:
	if gold_storage >= 10:
		# Trừ 10 vàng
		gold_storage -= 10
		gold_changed.emit(gold_storage)
		
		spawn_queue += 1
		_update_buy_button_text()
		print("💰 [MUA KIẾN] Thành công! Đang ấp trứng... Số lượng chờ: ", spawn_queue)
		
		# Khởi động máy ấp nếu nó đang nghỉ
		if spawn_timer.is_stopped():
			spawn_timer.start()
	else:
		print("❌ [MUA KIẾN] KHÔNG ĐỦ VÀNG! Cần 10 Vàng, hiện chỉ có: ", gold_storage)

func _on_spawn_timeout() -> void:
	if spawn_queue > 0:
		spawn_worker() # Gọi hàm sinh kiến có sẵn của bạn
		spawn_queue -= 1
		_update_buy_button_text()
		print("🥚 [ẤP TRỨNG] 1 Kiến đã ra đời! Còn lại trong hàng chờ: ", spawn_queue)
		
		# Nếu vẫn còn kiến trong hàng chờ, ấp tiếp con nữa (3s)
		if spawn_queue > 0:
			spawn_timer.start()

func _update_buy_button_text() -> void:
	if buy_button:
		buy_button.text = "Mua Nông Dân (10 Vàng) - Hàng chờ: " + str(spawn_queue)
		
# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE base.gd
# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE base.gd (TẠM THỜI ĐỔI THÀNH _input ĐỂ DEBUG BẤT CHẤP UI)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		spawn_worker()
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mouse_pos = get_global_mouse_position()
		var dist_x = abs(mouse_pos.x - global_position.x)
		var dist_y = abs(mouse_pos.y - global_position.y)
		
		# BẰNG CHỨNG LOG: In ra mọi cú click chuột trên màn hình để kiểm tra sai số tọa độ
		print("🖱️ [DEBUG CLICK] Chuột: ", mouse_pos, " | Nhà chính: ", global_position, " | Lệch X: ", dist_x, " Lệch Y: ", dist_y)
		
		if dist_x <= 32.0 and dist_y <= 32.0:
			if ui_layer:
				ui_layer.visible = !ui_layer.visible
				print("✅ [NHÀ CHÍNH] ĐÃ BẮT ĐƯỢC CLICK! Bật/tắt menu: ", ui_layer.visible)
				# Tạm thời bỏ get_viewport().set_input_as_handled() để xem log dễ hơn

func spawn_worker() -> void:
	if worker_scene:
		var worker = worker_scene.instantiate()
		worker.global_position = $SpawnPoint.global_position
		get_parent().add_child(worker)
		print("Đã xin 1 Nông dân!")

func add_resource(type: String, amount: int) -> void:
	if type == "gold":
		gold_storage += amount
		gold_changed.emit(gold_storage)
	elif type == "wood":
		wood_storage += amount
		wood_changed.emit(wood_storage)

# Hàm cho nông dân lấy tài nguyên từ Nhà chính (Ví dụ lấy 10 gỗ để đi xây)
func use_resource(type: String, amount: int) -> bool:
	if type == "wood":
		if wood_storage >= amount:
			wood_storage -= amount
			wood_changed.emit(wood_storage)
			return true
	elif type == "gold":
		if gold_storage >= amount:
			gold_storage -= amount
			gold_changed.emit(gold_storage)
			return true
	return false
# THÊM HÀM NÀY VÀO CUỐI FILE base.gd
func take_damage(amount: float) -> void:
	current_hp -= amount
	print("🏰 [CĂN CỨ] Bị tấn công! Máu còn: ", current_hp)
	
	if current_hp <= 0:
		print("💥 [CĂN CỨ] NHÀ CHÍNH ĐÃ BỊ PHÁ HỦY!")
		$ColorRect.color = Color.BLACK
		game_over.emit() # Phát tín hiệu cho toàn hệ thống biết Game Over
