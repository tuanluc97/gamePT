extends Node2D

@export var grid_size: float = 32.0
@export var wall_foundation_scene: PackedScene  # Móng Tường
@export var tower_foundation_scene: PackedScene # Móng Tháp
@export var trap_foundation_scene: PackedScene  # Móng Bẫy
@export var wood_node_scene: PackedScene
@export var gold_node_scene: PackedScene
var current_selected_foundation: PackedScene = null # Công trình đang được chọn để xây
var is_building_mode: bool = false
var astar_grid: AStarGrid2D
var monster_astar_grid: AStarGrid2D
var map_width: int = 500
var map_height: int = 500
var offset_x: int = -250
var offset_y: int = -250

# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE grid_map.gd
# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE grid_map.gd
func _ready() -> void:
	add_to_group("grid_manager")
	global_position = Vector2.ZERO 
	
	_init_astar_grid()
	call_deferred("_auto_align_and_block")
	_create_world_boundaries() 
	
	# Gọi hàm sinh mỏ gỗ ngẫu nhiên (Ví dụ sinh 20 mỏ rải rác)
	call_deferred("_spawn_random_wood_nodes", 20)
	queue_redraw()
	select_building_type("tower")
func _create_world_boundaries() -> void:
	var bounds = StaticBody2D.new()
	bounds.name = "WorldBounds"
	
	var rect = Rect2(offset_x, offset_y, map_width, map_height)
	var thickness = 60.0
	
	# BẢN VÁ: Khi dời gốc tọa độ về (0,0), tâm Y của Tường Trái/Phải là chính giữa map (rect.size.y / 2)
	var center_x = rect.size.x / 2.0
	var center_y = rect.size.y / 2.0
	
	var shapes = [
		[Vector2(rect.position.x - thickness/2.0, center_y), Vector2(thickness, rect.size.y)], # Trái
		[Vector2(rect.end.x + thickness/2.0, center_y), Vector2(thickness, rect.size.y)],      # Phải
		[Vector2(center_x, rect.position.y - thickness/2.0), Vector2(rect.size.x + thickness*2.0, thickness)], # Trên
		[Vector2(center_x, rect.end.y + thickness/2.0), Vector2(rect.size.x + thickness*2.0, thickness)]       # Dưới
	]
	
	for s in shapes:
		var coll = CollisionShape2D.new()
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = s[1]
		coll.shape = rect_shape
		coll.position = s[0]
		bounds.add_child(coll)
		
	add_child(bounds)
	print("🚧 [GRID MAP DEBUG] Đã dựng tường bao quanh khung: (0,0) -> (", map_width, ",", map_height, ")")
	
func _debug_check_objects() -> void:
	var bases = get_tree().get_nodes_in_group("main_base")
	if bases.size() > 0:
		for b in bases:
			print("[DEBUG CHECK] Tên node Base: ", b.name)
			#print("[DEBUG CHECK] Tọa độ global_position của Base: ", b.global_position)
	else:
		print("[DEBUG CHECK CẢNH BÁO] Không tìm thấy Node nào trong group 'main_base'!")
# CHỈ THÊM/SỬA ĐÚNG HÀM NÀY TRONG FILE grid_map.gd
# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE grid_map.gd
func _auto_align_and_block() -> void:
	for b in get_tree().get_nodes_in_group("main_base"):
		var snapped_x = round(b.global_position.x / grid_size) * grid_size
		var snapped_y = round(b.global_position.y / grid_size) * grid_size
		b.global_position = Vector2(snapped_x, snapped_y)
		
		# KHÔI PHỤC LẠI ĐOẠN KHÓA LƯỚI BỊ THIẾU
		var cell_x = int(round(b.global_position.x / grid_size))
		var cell_y = int(round(b.global_position.y / grid_size))
		astar_grid.set_point_solid(Vector2i(cell_x, cell_y), true)
		astar_grid.set_point_solid(Vector2i(cell_x - 1, cell_y), true)
		astar_grid.set_point_solid(Vector2i(cell_x, cell_y - 1), true)
		astar_grid.set_point_solid(Vector2i(cell_x - 1, cell_y - 1), true)

	for res in get_tree().get_nodes_in_group("hidden_resources"):
		res.global_position = get_cell_center(res.global_position)
func _init_astar_grid() -> void:
	astar_grid = AStarGrid2D.new()
	astar_grid.region = Rect2i(-map_width / 2, -map_height / 2, map_width, map_height)
	astar_grid.cell_size = Vector2(grid_size, grid_size)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar_grid.update()
	
	monster_astar_grid = AStarGrid2D.new()
	monster_astar_grid.region = Rect2i(-map_width / 2, -map_height / 2, map_width, map_height)
	monster_astar_grid.cell_size = Vector2(grid_size, grid_size)
	monster_astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	monster_astar_grid.update()

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
# CHỈ THAY THẾ ĐÚNG HÀM NÀY TRONG FILE grid_map.gd
# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE grid_map.gd
# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE grid_map.gd
func _draw() -> void:
	print("\n--- [DEBUG GRID] BẮT ĐẦU VẼ VIỀN MAP ---")
	
	# Vẽ một viền màu Đen ôm SÁT LỀ ngoài bản đồ (dùng hàm grow để đẩy độ dày 7.5 ra ngoài, không lẹm vào lưới)
	var map_rect = Rect2(offset_x, offset_y, map_width, map_height)
	var outer_rect = map_rect.grow(7.5) 
	draw_rect(outer_rect, Color.BLACK, false, 15.0)
	
	for b in get_tree().get_nodes_in_group("main_base"):
		draw_circle(b.global_position, 5.0, Color.RED)
		
	print("🖌️ [GRID MAP DEBUG] Vùng chơi thực tế an toàn: ", map_rect)

# Chuyển đổi Pixel sang Ô Lưới
func local_to_map(pos: Vector2) -> Vector2i:
	return Vector2i(floor(pos.x / grid_size), floor(pos.y / grid_size))

# Trả về tọa độ chính GIỮA lòng ô vuông lưới (Dành cho Kiến)
func get_cell_center(pos: Vector2) -> Vector2:
	var cell = local_to_map(pos)
	return Vector2(cell.x * grid_size + grid_size / 2.0, cell.y * grid_size + grid_size / 2.0)

# Hàm tìm đường A*
# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE grid_map.gd
func get_path_for_ant(start_pos: Vector2, target_pos: Vector2) -> Array[Vector2]:
	var start_cell = local_to_map(start_pos)
	var target_cell = local_to_map(target_pos)
	
	start_cell.x = clamp(start_cell.x, offset_x, offset_x + map_width - 1)
	start_cell.y = clamp(start_cell.y, offset_y, offset_y + map_height - 1)
	target_cell.x = clamp(target_cell.x, offset_x, offset_x + map_width - 1)
	target_cell.y = clamp(target_cell.y, offset_y, offset_y + map_height - 1)
	
	# ==============================================================
	# THỦ THUẬT TRÁNH LỖI A*: Tạm mở khóa Ô bắt đầu và Ô đích
	# ==============================================================
	var start_was_solid = astar_grid.is_point_solid(start_cell)
	var target_was_solid = astar_grid.is_point_solid(target_cell)
	
	if start_was_solid: astar_grid.set_point_solid(start_cell, false)
	if target_was_solid: astar_grid.set_point_solid(target_cell, false)
	
	# A* sẽ vẽ đường trơn tru kể cả khi đích đến là bức tường
	var path_cells = astar_grid.get_id_path(start_cell, target_cell)
	
	# Ngay lập tức Khóa lại vật cản để duy trì vật lý cho Game
	if start_was_solid: astar_grid.set_point_solid(start_cell, true)
	if target_was_solid: astar_grid.set_point_solid(target_cell, true)
	# ==============================================================
	
	var path_positions: Array[Vector2] = []
	for cell in path_cells:
		path_positions.append(Vector2(cell.x * grid_size + grid_size / 2.0, cell.y * grid_size + grid_size / 2.0))
	return path_positions

func update_wall_obstacle(pos: Vector2, is_solid: bool, is_trap: bool = false) -> void:
	var cell = local_to_map(pos)
	# Kiến và Hero coi Bẫy là Tường vững chắc
	astar_grid.set_point_solid(cell, is_solid)
	
	# Quái vật coi Bẫy là đường bằng phẳng
	if not is_trap:
		monster_astar_grid.set_point_solid(cell, is_solid)
# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE grid_map.gd
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		# BẰNG CHỨNG LOG: Bắt tín hiệu xem chuột số mấy đang click xuống bản đồ
		print("🚨 [BẮT CLICK] Lưới nhận Chuột số: ", event.button_index, " | Chế độ xây: ", is_building_mode)
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			if is_building_mode:
				place_foundation_at_mouse()
			else:
				# BẰNG CHỨNG LOG: Click đất trống trả về Menu mặc định
				print("🌱 [GRID MAP] Click vào đất trống! Mở Menu Xây dựng.")
				var uis = get_tree().get_nodes_in_group("unified_ui")
				if uis.size() > 0 and uis[0].has_method("switch_context"):
					uis[0].switch_context("default")
			
		# 2. Bấm chuột Phải (Nút số 2): Chức năng Xóa móng / Thoát xây
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			var mouse_pos = get_global_mouse_position()
			var snap_pos = get_cell_center(mouse_pos)
			
			var found_foundation = false
			var nodes = get_tree().get_nodes_in_group("foundations")
			
			for n in nodes:
				if is_instance_valid(n) and n.global_position.distance_to(snap_pos) < 5.0:
					# Nếu có thợ đang lấy gỗ cho móng này thì hủy lệnh của thợ
					if "is_wood_assigned" in n and n.is_wood_assigned:
						n.is_wood_assigned = false
					
					n.queue_free()
					update_wall_obstacle(snap_pos, false) # Trả lại đường đi cho A*
					found_foundation = true
					print("🗑️ [XÓA MÓNG] Thành công! Đã đập bỏ móng tại: ", snap_pos)
					break
			
			# Nếu tay đang cầm công cụ xây mà click chuột phải ra bãi đất trống
			if not found_foundation and is_building_mode:
				is_building_mode = false
				current_selected_foundation = null
				print("👉 [XÂY DỰNG] Đã thoát chế độ xây do click chuột phải ra đất trống.")
# THÊM HÀM NÀY VÀO FILE grid_map.gd
func place_foundation_at_mouse() -> void:
	if current_selected_foundation == null:
		print("👉 [LỖI XÂY DỰNG] Chưa chọn công trình nào để xây!")
		return
		
	var mouse_pos = get_global_mouse_position()
	var cell = local_to_map(mouse_pos)
	var snap_pos = get_cell_center(mouse_pos)
	
	if is_tile_occupied(snap_pos) or astar_grid.is_point_solid(cell):
		print("👉 [XÂY DỰNG] Ô này đã có vật cản!")
		return
		
	var foundation = current_selected_foundation.instantiate()
	foundation.global_position = snap_pos
	get_parent().add_child(foundation)
	
	var is_trap = (current_selected_foundation == trap_foundation_scene)
	
	# BẢN VÁ LỖI: XÓA BỎ lệnh update_wall_obstacle chặn đường ở đây. 
	# Móng nhà là đất bằng, ai cũng giẫm lên được!
	
	# BẰNG CHỨNG LOG:
	print("👉 [XÂY DỰNG] Đặt móng tại: ", snap_pos, " | Kiến và Quái VẪN ĐI XUYÊN QUA được!")
	
func is_tile_occupied(pos: Vector2) -> bool:
	for f in get_tree().get_nodes_in_group("foundations"):
		if f.global_position.distance_to(pos) < 5.0: return true
	for w in get_tree().get_nodes_in_group("walls"):
		if w.global_position.distance_to(pos) < 5.0: return true
	return false
# THÊM 2 HÀM NÀY VÀO CUỐI FILE grid_map.gd

# 1. Hàm tính tổng số lượng gỗ hiện còn trên tất cả các mỏ gỗ trên bản đồ
# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE grid_map.gd
func _get_total_wood_on_map() -> int:
	var total_wood = 0
	# Gộp danh sách cả mỏ đã hiện (wood_nodes) và mỏ đang ẩn sương mù (hidden_resources)
	var all_nodes = get_tree().get_nodes_in_group("wood_nodes") + get_tree().get_nodes_in_group("hidden_resources")
	
	for node in all_nodes:
		if is_instance_valid(node) and "current_wood" in node:
			total_wood += node.current_wood
			
	return total_wood

# THAY THẾ HOẶC THÊM HÀM NÀY TRONG FILE grid_map.gd
var wood_check_timer: float = 0.0

# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE grid_map.gd
func _process(delta: float) -> void:
	wood_check_timer += delta
	if wood_check_timer >= 2.0:
		wood_check_timer = 0.0
		_maintain_wood_supply()
		_maintain_gold_supply() # THÊM DÒNG NÀY: Duy trì cả mỏ Vàng
func _maintain_wood_supply() -> void:
	if wood_node_scene == null: return
	
	var current_total = _get_total_wood_on_map()
	var max_cap = 500 # Giới hạn tối đa 500 gỗ trên bản đồ
	
	# Nếu tổng lượng gỗ trên bản đồ đang nhỏ hơn 500
	if current_total < max_cap:
		var deficit = max_cap - current_total # Số gỗ còn thiếu
		
		# Chỉ sinh mỏ mới nếu số gỗ thiếu >= 30 (đủ cho 1 mỏ nhỏ)
		if deficit >= 30:
			# Lựa chọn ngẫu nhiên vị trí trong khung viền bản đồ (-1900 đến 1900)
			var rand_pos = Vector2(randf_range(-1900, 1900), randf_range(-1900, 1900))
			rand_pos = get_cell_center(rand_pos)
			var cell = local_to_map(rand_pos)
			
			# Ô đất phải trống (chưa có vật cản)
			if not astar_grid.is_point_solid(cell):
				var wood = wood_node_scene.instantiate()
				wood.global_position = rand_pos
				
				# Sinh giá trị ngẫu nhiên từ 30 đến 50 gỗ (nhưng không vượt quá số gỗ thiếu)
				var rand_val = min(randi_range(30, 50), deficit)
				wood.set("max_wood", rand_val)
				wood.set("current_wood", rand_val)
				
				get_parent().add_child(wood)
				update_wall_obstacle(rand_pos, true)
				
				# LOG BẰNG CHỨNG: In ra mỗi khi mỏ mới xuất hiện thành công
				print("🌲 [TÀI NGUYÊN] Đã sinh mỏ gỗ mới (+", rand_val, " gỗ) tại: ", rand_pos, " | Tổng gỗ toàn map hiện tại: ", _get_total_wood_on_map(), "/", max_cap)
				
# THÊM HÀM NÀY VÀO CUỐI FILE grid_map.gd
func _spawn_random_wood_nodes(count: int) -> void:
	if wood_node_scene == null:
		print("🚨 [LỖI] Chưa kéo thả file 'wood_node.tscn' vào GridMap trong Inspector!")
		return
		
	var spawned = 0
	# Lặp dư ra chút đỉnh để lỡ trúng ô bị kẹt thì tìm ô khác
	for i in range(count * 2): 
		if spawned >= count: break
		
		# Sinh tọa độ an toàn trong vùng viền map (-1900 đến 1900)
		var rand_pos = Vector2(randf_range(-1900, 1900), randf_range(-1900, 1900))
		rand_pos = get_cell_center(rand_pos)
		var cell = local_to_map(rand_pos)
		
		# Chỉ sinh mỏ gỗ nếu ô đất đó đang KHÔNG bị vật cản khác đè lên
		if not astar_grid.is_point_solid(cell):
			var wood = wood_node_scene.instantiate()
			wood.global_position = rand_pos
			
			# Thiết lập ngẫu nhiên lượng gỗ từ 30 đến 50
			var rand_val = randi_range(30, 50)
			wood.set("max_wood", rand_val)
			wood.set("current_wood", rand_val)
			
			get_parent().add_child(wood)
			# Khóa ô lưới lại để Kiến không đi xuyên ngang qua mỏ gỗ
			update_wall_obstacle(rand_pos, true)
			spawned += 1
			
	print("🌲 [TÀI NGUYÊN] Đã rải thành công ", spawned, " mỏ gỗ trên bản đồ!")				
	
# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE grid_map.gd
func select_building_type(type: String) -> void:
	is_building_mode = true
	match type:
		"wall":
			current_selected_foundation = wall_foundation_scene
		"tower":
			current_selected_foundation = tower_foundation_scene
		"trap":
			current_selected_foundation = trap_foundation_scene
			# BẰNG CHỨNG LOG: Kiểm tra xem biến chứa scene bẫy có tồn tại không
			print("🏗️ [GRID DEBUG] Đã nhận lệnh XÂY BẪY! Dữ liệu trap_foundation_scene là: ", trap_foundation_scene)
		_:
			is_building_mode = false
			current_selected_foundation = null
			print("🏗️ [GRID DEBUG] Hủy chọn công trình.")# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE grid_map.gd
func get_path_for_monster(start_pos: Vector2, end_pos: Vector2) -> Array[Vector2]:
	var start_cell = local_to_map(start_pos)
	var end_cell = local_to_map(end_pos)
	
	if not monster_astar_grid.is_in_boundsv(start_cell) or not monster_astar_grid.is_in_boundsv(end_cell):
		return []
		
	var path_cells = monster_astar_grid.get_id_path(start_cell, end_cell)
	var path_positions: Array[Vector2] = []
	
	for cell in path_cells:
		# BẢN VÁ LỖI: Dùng hàm của AStarGrid thay vì map_to_local, sau đó cộng thêm nửa ô để lấy đúng tâm
		var world_pos = monster_astar_grid.get_point_position(cell)
		path_positions.append(world_pos + Vector2(grid_size / 2.0, grid_size / 2.0))
		
	return path_positions

func _get_total_gold_on_map() -> int:
	var total_gold = 0
	var all_nodes = get_tree().get_nodes_in_group("gold_nodes") + get_tree().get_nodes_in_group("hidden_resources")
	for node in all_nodes:
		if is_instance_valid(node) and "current_gold" in node:
			total_gold += node.current_gold
	return total_gold

func _maintain_gold_supply() -> void:
	if gold_node_scene == null: return
	
	var current_total = _get_total_gold_on_map()
	var max_cap = 500 # Giới hạn 500 Vàng
	
	if current_total < max_cap:
		var deficit = max_cap - current_total
		if deficit >= 30:
			var rand_pos = Vector2(randf_range(-1900, 1900), randf_range(-1900, 1900))
			rand_pos = get_cell_center(rand_pos)
			var cell = local_to_map(rand_pos)
			
			if not astar_grid.is_point_solid(cell):
				var gold = gold_node_scene.instantiate()
				gold.global_position = rand_pos
				
				var rand_val = min(randi_range(30, 50), deficit)
				gold.set("max_gold", rand_val)
				gold.set("current_gold", rand_val)
				
				get_parent().add_child(gold)
				update_wall_obstacle(rand_pos, true)
				
				# LOG BẰNG CHỨNG
				print("🪙 [TÀI NGUYÊN] Đã sinh mỏ Vàng mới (+", rand_val, ") tại: ", rand_pos, " | Tổng Vàng toàn map: ", _get_total_gold_on_map(), "/", max_cap)
# THÊM HÀM NÀY VÀO CUỐI FILE grid_map.gd
func setup_map_size(w: int, h: int) -> void:
	map_width = w
	map_height = h
	# BẢN VÁ: Dời Gốc Tọa Độ (Anchor) về chuẩn (0,0) thay vì tâm map!
	offset_x = 0
	offset_y = 0
	print("📏 [GRID MAP] Kích thước lưới được cập nhật: ", w, "x", h, " | Gốc Tọa Độ: (0,0)")
	
	for child in get_children():
		if child is StaticBody2D: 
			child.queue_free()
	_create_world_boundaries()
	queue_redraw()
