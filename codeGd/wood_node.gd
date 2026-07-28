extends Area2D

@export var max_wood: int = 500
var current_wood: int
var is_discovered: bool = false # Trạng thái khám phá

func _ready() -> void:
	current_wood = max_wood
	hide() # Tàng hình khi mới vào game
	add_to_group("hidden_resources")
	
	# Xóa khỏi nhóm wood_nodes để thợ mỏ không tới đào khi chưa thấy
	if is_in_group("wood_nodes"):
		remove_from_group("wood_nodes")

# Hàm cho Kiến Trinh Sát gọi khi đi ngang qua
func discover() -> void:
	if not is_discovered:
		is_discovered = true
		show() # Hiện hình
		remove_from_group("hidden_resources")
		add_to_group("wood_nodes") # Báo cho thợ mỏ biết!
		Global.log_event.emit("success", "Trinh sát đã phát hiện Mỏ gỗ!")

func harvest(amount: int) -> int:
	var actual_harvested = min(amount, current_wood)
	current_wood -= actual_harvested
	if current_wood <= 0:
		queue_free() 
	return actual_harvested
	
# THÊM/SỬA 2 HÀM NÀY VÀO FILE wood_node.gd
func _process(_delta: float) -> void:
	# Yêu cầu Godot vẽ lại số gỗ liên tục mỗi khung hình
	queue_redraw()

func _draw() -> void:
	# Chỉ vẽ số khi mỏ đã được Trinh sát phát hiện (không bị hide) và còn gỗ
	if visible and "current_wood" in self and current_wood > 0:
		var text = str(current_wood) + " Gỗ"
		# Vẽ chữ lùi xuống dưới mỏ (Tọa độ Y = 45)
		draw_string(ThemeDB.fallback_font, Vector2(0, 45), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.WHITE)
