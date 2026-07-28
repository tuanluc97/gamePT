extends Area2D

@export var max_build_progress: float = 100.0
var current_build_progress: float = 0.0
var is_wood_assigned: bool = false # Đánh dấu xem đã có thợ nào đi lấy gỗ cho móng này chưa

@export var real_wall_scene: PackedScene
@onready var progress_bar: ProgressBar = $ProgressBar

# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE wall_foundation.gd
func _ready() -> void:
	progress_bar.max_value = max_build_progress
	progress_bar.value = 0.0
	
	# BẢN VÁ: Vô hiệu hóa tính năng "chặn chuột" của UI, cho phép click xuyên qua móng
	if has_node("ColorRect"):
		$ColorRect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if has_node("ProgressBar"):
		$ProgressBar.mouse_filter = Control.MOUSE_FILTER_IGNORE

# Nhiều nông dân cùng gọi hàm này thì tiến độ càng tăng nhanh
func build(amount: float) -> void:
	current_build_progress += amount
	progress_bar.value = current_build_progress
	
	if current_build_progress >= max_build_progress:
		finish_construction()

func finish_construction() -> void:
	if real_wall_scene:
		var real_wall = real_wall_scene.instantiate()
		real_wall.global_position = global_position
		get_parent().add_child(real_wall)
		Global.log_event.emit("build", "Đã hoàn thành một công trình!")
		# Báo cho BuildManager biết để bít đường A*
		var grids = get_tree().get_nodes_in_group("grid_manager")
		if grids.size() > 0:
			grids[0].update_wall_obstacle(global_position, true)
			
	queue_free()
