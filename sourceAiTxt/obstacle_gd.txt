extends StaticBody2D

func _ready() -> void:
	add_to_group("obstacles")
	
	# Báo cho GridMap chặn đường A* tại vị trí cục đá này
	var grids = get_tree().get_nodes_in_group("grid_manager")
	if grids.size() > 0 and grids[0].has_method("update_wall_obstacle"):
		# Truyền tọa độ cục đá, tham số true (là vật cản), false (không phải là bẫy)
		grids[0].update_wall_obstacle(global_position, true, false)
		
		# BẰNG CHỨNG LOG: Xác minh thuật toán tìm đường đã được cập nhật
		print("🪨 [VẬT CẢN] Đã chặn đường A* tại: ", global_position)
