extends Node2D

@export var grid_size: float = 32.0
@export var foundation_scene: PackedScene

var is_building_mode: bool = false
var astar_grid: AStarGrid2D

var map_width: int = 500
var map_height: int = 500
var offset_x: int = -250
var offset_y: int = -250

# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE grid_map.gd
func _ready() -> void:
	print(">>> [DEBUG CHECK] Hàm _ready() của GridMap ĐÃ CHẠY! <<<")
	add_to_group("grid_manager")
	
	# In ra tọa độ thế giới của bản thân GridMap
	print("[DEBUG CHECK] GridMap global_position: ", global_position)
	
	_init_astar_grid()
	call_deferred("_debug_check_objects")

func _debug_check_objects() -> void:
	var bases = get_tree().get_nodes_in_group("main_base")
	if bases.size() > 0:
		for b in bases:
			print("[DEBUG CHECK] Tên node Base: ", b.name)
			print("[DEBUG CHECK] Tọa độ global_position của Base: ", b.global_position)
	else:
		print("[DEBUG CHECK CẢNH BÁO] Không tìm thấy Node nào trong group 'main_base'!")
# CHỈ THÊM/SỬA ĐÚNG HÀM NÀY TRONG FILE grid_map.gd
func _auto_align_and_block() -> void:
	print("--- [DEBUG BUG 1] BẮT ĐẦU KIỂM TRA TỌA ĐỘ ---")
	for b in get_tree().get_nodes_in_group("main_base"):
		var raw_pos = b.global_position
		var cell = local_to_map(raw_pos)
		var snapped_pos = Vector2(cell.x * grid_size, cell.y * grid_size)
		
		print("1. Tọa độ thực tế (Global Position) của Nhà chính: ", raw_pos)
		print("2. Ô lưới (Local to Map) mà nó đang đứng: ", cell)
		print("3. Tọa độ tính toán theo góc ô lưới (Snap): ", snapped_pos)
		
		# Gán lại vị trí để ép nhà chính khớp vào góc ô lưới
		b.global_position = snapped_pos
func _init_astar_grid() -> void:
	astar_grid = AStarGrid2D.new()
	astar_grid.cell_size = Vector2(grid_size, grid_size)
	astar_grid.region = Rect2i(offset_x, offset_y, map_width, map_height) 
	astar_grid.offset = Vector2.ZERO 
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()

# --- HÀM DEBUG TỌA ĐỘ ---
func _debug_check_base_position() -> void:
	var bases = get_tree().get_nodes_in_group("main_base")
	if bases.size() > 0:
		for b in bases:
			print("[DEBUG] Tìm thấy main_base: ", b.name, " tại Pixel gốc: ", b.global_position)
			
			# Tự động gỡ lỗi "Nhân đôi Base" nếu người dùng quên xóa group ở ColorRect
			if not b is StaticBody2D:
				print("[CẢNH BÁO MÀU ĐỎ] Node '", b.name, "' không phải là StaticBody2D (có thể là ColorRect). Hãy gỡ nó khỏi group 'main_base'!")
			else:
				var cell = local_to_map(b.global_position)
				print("[DEBUG] AStar nhận diện Nhà chính nằm ở Ô Lưới (Cell): ", cell)
	else:
		print("[LỖI] Không tìm thấy Nhà chính trong group 'main_base'")

	var resources = get_tree().get_nodes_in_group("hidden_resources")
	if resources.size() > 0:
		print("[DEBUG] Mỏ tài nguyên đầu tiên nằm ở: ", resources[0].global_position)

# --- VẼ GIAO DIỆN DEBUG ---
func _draw() -> void:
	var color = Color(1.0, 1.0, 1.0, 0.4) # Vẽ nét trắng rõ
	var draw_limit = 1000 
	
	# Vẽ các đường chỉ bao bọc bên ngoài ô lưới (VD: 0, 32, 64)
	for x in range(-draw_limit, draw_limit + int(grid_size), int(grid_size)):
		draw_line(Vector2(x, -draw_limit), Vector2(x, draw_limit), color, 1.0)
	for y in range(-draw_limit, draw_limit + int(grid_size), int(grid_size)):
		draw_line(Vector2(-draw_limit, y), Vector2(draw_limit, y), color, 1.0)

	# Vẽ Chấm Đỏ tại Tâm Nhà chính (Pixel gốc)
	for b in get_tree().get_nodes_in_group("main_base"):
		draw_circle(to_local(b.global_position), 5.0, Color.RED)
	
	# Vẽ Chấm Xanh tại Tâm Mỏ
	for res in get_tree().get_nodes_in_group("hidden_resources"):
		draw_circle(to_local(res.global_position), 5.0, Color.GREEN)

# ====================================================================
# CÁC HÀM CỐT LÕI (BẮT BUỘC PHẢI CÓ)
# ====================================================================

# Chuyển đổi Pixel sang Ô Lưới
func local_to_map(pos: Vector2) -> Vector2i:
	return Vector2i(floor(pos.x / grid_size), floor(pos.y / grid_size))

# Trả về tọa độ chính GIỮA lòng ô vuông lưới (Dành cho Kiến)
func get_cell_center(pos: Vector2) -> Vector2:
	var cell = local_to_map(pos)
	return Vector2(cell.x * grid_size + grid_size / 2.0, cell.y * grid_size + grid_size / 2.0)

# Hàm tìm đường A*
func get_path_for_ant(start_pos: Vector2, target_pos: Vector2) -> Array[Vector2]:
	var start_cell = local_to_map(start_pos)
	var target_cell = local_to_map(target_pos)
	
	start_cell.x = clamp(start_cell.x, offset_x, offset_x + map_width - 1)
	start_cell.y = clamp(start_cell.y, offset_y, offset_y + map_height - 1)
	target_cell.x = clamp(target_cell.x, offset_x, offset_x + map_width - 1)
	target_cell.y = clamp(target_cell.y, offset_y, offset_y + map_height - 1)
	
	var path_cells = astar_grid.get_id_path(start_cell, target_cell)
	var path_positions: Array[Vector2] = []
	for cell in path_cells:
		path_positions.append(Vector2(cell.x * grid_size + grid_size / 2.0, cell.y * grid_size + grid_size / 2.0))
	return path_positions

func update_wall_obstacle(global_pos: Vector2, is_solid: bool) -> void:
	astar_grid.set_point_solid(local_to_map(global_pos), is_solid)

# --- CHẾ ĐỘ XÂY DỰNG TẠM THỜI GIỮ TRỐNG ĐỂ TẬP TRUNG DEBUG ---
func _unhandled_input(event: InputEvent) -> void: pass
