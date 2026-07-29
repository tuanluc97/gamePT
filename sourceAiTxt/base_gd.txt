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
	input_pickable = true
	current_hp = Global.base_hp if typeof(Global) != TYPE_NIL and "base_hp" in Global else 200.0
	
	# Tạo Timer đếm 3s sinh Kiến
	spawn_timer = Timer.new()
	spawn_timer.wait_time = 3.0
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_on_spawn_timeout)
	add_child(spawn_timer)
	
	# Đã xóa bỏ đoạn tự tạo ui_layer và buy_button cũ rườm rà
	
	# Cấp 50 Vàng khởi đầu
	await get_tree().create_timer(0.1).timeout
	add_resource("gold", 50)
	print("🏰 [NHÀ CHÍNH] Khởi tạo thành công 50 Vàng ban đầu.")
func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("🏰 [NHÀ CHÍNH] Đã click vào Nhà! Báo cho UI mở Menu Base.")
		var uis = get_tree().get_nodes_in_group("unified_ui")
		if uis.size() > 0 and uis[0].has_method("switch_context"):
			uis[0].switch_context("base")
			
func _on_buy_pressed() -> void:
	if gold_storage >= 10:
		gold_storage -= 10
		gold_changed.emit(gold_storage) # Phát tín hiệu trừ vàng cho UnifiedUI
		
		spawn_queue += 1
		_update_buy_ui()
		Global.log_event.emit("success", "Đã thêm 1 Kiến vào hàng chờ! Hàng chờ: " + str(spawn_queue))
		print("💰 [MUA KIẾN] Mua thành công! Vàng còn: ", gold_storage, " | Hàng chờ: ", spawn_queue)
		
		if spawn_timer.is_stopped():
			spawn_timer.start()
	else:
		Global.log_event.emit("alert", "Không đủ Vàng! Cần 10 Vàng (Hiện có: " + str(gold_storage) + ")")
		print("❌ [MUA KIẾN] Không đủ Vàng! Hiện có: ", gold_storage)
func _update_buy_ui() -> void:
	var uis = get_tree().get_nodes_in_group("unified_ui")
	if uis.size() > 0 and uis[0].has_method("update_buy_queue"):
		uis[0].update_buy_queue(spawn_queue)
		
func _on_spawn_timeout() -> void:
	if spawn_queue > 0:
		spawn_worker()
		spawn_queue -= 1
		
		# BẢN VÁ LỖI: Gọi đúng hàm kết nối với Unified UI để nó cập nhật lại Text trên màn hình
		_update_buy_ui() 
		
		# BẰNG CHỨNG LOG: Xác minh mảng hàng chờ thực sự đã được trừ đi
		print("🥚 [NHÀ CHÍNH] 1 Nông dân ra đời! Hàng chờ hiện tại cập nhật thành: ", spawn_queue)
		Global.log_event.emit("success", "1 Kiến nông dân vừa ra đời!")
		
		# Nếu vẫn còn kiến trong hàng chờ, tiếp tục chạy timer
		if spawn_queue > 0:
			spawn_timer.start()

func _update_buy_button_text() -> void:
	if buy_button:
		buy_button.text = "Mua Nông Dân (10 Vàng) - Hàng chờ: " + str(spawn_queue)
		
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		spawn_worker()
		
	# BẢN VÁ CLICK: Báo cho UnifiedUI chuyển sang màn hình Base
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mouse_pos = get_global_mouse_position()
		var dist_x = abs(mouse_pos.x - global_position.x)
		var dist_y = abs(mouse_pos.y - global_position.y)
		
		if dist_x <= 32.0 and dist_y <= 32.0:
			print("🏰 [NHÀ CHÍNH] Đã click vào Nhà! Báo cho UnifiedUI mở BaseMenu.")
			var uis = get_tree().get_nodes_in_group("unified_ui")
			if uis.size() > 0 and uis[0].has_method("switch_context"):
				uis[0].switch_context("base")
				
func spawn_worker() -> void:
	if worker_scene:
		var worker = worker_scene.instantiate()
		worker.global_position = $SpawnPoint.global_position
		get_parent().add_child(worker)
		print("Đã xin 1 Nông dân!")

func add_resource(type: String, amount: int) -> void:
	if type == "gold":
		gold_storage += amount
		gold_changed.emit(gold_storage) # Phải có dòng này để báo cho Unified UI
	elif type == "wood":
		wood_storage += amount
		wood_changed.emit(wood_storage) # Phải có dòng này để báo cho Unified UI

func use_resource(type: String, amount: int) -> bool:
	if type == "wood":
		if wood_storage >= amount:
			wood_storage -= amount
			wood_changed.emit(wood_storage) # Phải có dòng này để trừ số Gỗ trên UI
			return true
	elif type == "gold":
		if gold_storage >= amount:
			gold_storage -= amount
			gold_changed.emit(gold_storage) # Phải có dòng này để trừ số Vàng trên UI
			return true
	return false
# THÊM HÀM NÀY VÀO CUỐI FILE base.gd
func take_damage(amount: float) -> void:
	current_hp -= amount
	Global.log_event.emit("alert", "CẢNH BÁO: Nhà chính đang bị cắn! Máu: " + str(current_hp))
	
	if current_hp <= 0:
		print("💥 [CĂN CỨ] NHÀ CHÍNH ĐÃ BỊ PHÁ HỦY!")
		$ColorRect.color = Color.BLACK
		game_over.emit() # Phát tín hiệu cho toàn hệ thống biết Game Over
