extends Area2D

@export var max_gold: int = 500
var current_gold: int
var is_discovered: bool = false # Trạng thái khám phá

func _ready() -> void:
	current_gold = max_gold
	hide() # Tàng hình khi mới vào game
	add_to_group("hidden_resources")
	
	# Xóa khỏi nhóm gold_nodes để thợ mỏ không tới đào khi chưa thấy
	if is_in_group("gold_nodes"):
		remove_from_group("gold_nodes")

# Hàm cho Kiến Trinh Sát gọi khi đi ngang qua
func discover() -> void:
	if not is_discovered:
		is_discovered = true
		show() # Hiện hình
		remove_from_group("hidden_resources")
		add_to_group("gold_nodes") # Báo cho thợ mỏ biết!
		Global.log_event.emit("success", "Trinh sát đã phát hiện Mỏ vàng")

func harvest(amount: int) -> int:
	var actual_harvested = min(amount, current_gold)
	current_gold -= actual_harvested
	if current_gold <= 0:
		queue_free() 
	return actual_harvested
