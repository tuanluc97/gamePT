extends StaticBody2D

signal gold_changed(new_amount: int)
signal wood_changed(new_amount: int)

var gold_storage: int = 0
var wood_storage: int = 0
var current_hp: float = 200.0

@export var worker_scene: PackedScene

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		spawn_worker()

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
	# BẰNG CHỨNG LOG: Căn cứ báo cáo khi bị trừ máu
	print("🏰 [CĂN CỨ] Bị tấn công! Máu còn: ", current_hp)
	
	if current_hp <= 0:
		print("💥 [CĂN CỨ] NHÀ CHÍNH ĐÃ BỊ PHÁ HỦY! GAME OVER!")
		# Tạm thời khi chết sẽ đổi màu đen để biểu diễn (sau này có thể làm màn hình Game Over)
		$ColorRect.color = Color.BLACK
