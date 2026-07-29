extends CharacterBody2D

enum Job { NONE, GOLD_MINER, WOOD_CHOPPER, BUILDER, SCOUT }
enum State { IDLE, MOVING_TO_TARGET, WORKING, RETURNING_TO_BASE, MOVING_TO_BASE_FOR_WOOD }

@export var current_job: Job = Job.SCOUT
var current_state: State = State.IDLE

@export var speed: float = 120.0
@export var build_speed: float = 12.5 
var vision_radius: float = 150.0 

var agent_radius: float = 4.0 
@export var agent_color: Color = Color.PINK 

var carried_gold: int = 0
var carried_wood: int = 0
var has_wood_for_build: bool = false

var target_gold_node: Area2D = null
var target_wood_node: Area2D = null
var target_foundation: Area2D = null
var main_base: Node2D = null

var grid_manager: Node2D = null
var current_path: Array[Vector2] = []

@onready var harvest_timer: Timer = $HarvestTimer

# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE worker.gd
func _ready() -> void:
	add_to_group("workers")
	if typeof(Global) != TYPE_NIL and "worker_speed" in Global:
		speed = Global.worker_speed
	
	# BẰNG CHỨNG LOG: Quét vật lý ngay khi đẻ để tìm thủ phạm
	var collision_test = move_and_collide(Vector2.ZERO, true) 
	if collision_test:
		var collider = collision_test.get_collider()
		print("🚨 [NÔNG DÂN] BỊ KẸT TẠI: ", global_position, " | Đang nằm kẹt bên trong vật thể: ", collider.name)
	else:
		print("✅ [NÔNG DÂN] Sinh ra an toàn tại: ", global_position)
	harvest_timer.wait_time = 5.0 # Mặc định 5s như bạn yêu cầu
	harvest_timer.timeout.connect(_on_harvest_finished)
	queue_redraw()
	
	var bases = get_tree().get_nodes_in_group("main_base")
	if bases.size() > 0: main_base = bases[0]
		
	await get_tree().physics_frame
	var grids = get_tree().get_nodes_in_group("grid_manager")
	if grids.size() > 0: grid_manager = grids[0]
		
	if grid_manager and grid_manager.has_method("get_cell_center"):
		# Đẩy nhẹ vị trí khởi tạo ra khỏi tâm ô để tránh chồng chéo va chạm vật lý lúc đẻ nhiều con
		global_position = grid_manager.get_cell_center(global_position)
		
	evaluate_job()
	
	# BẰNG CHỨNG LOG: Kiểm tra ngay xem sau khi nhận việc, đường đi có bị rỗng không
	#print("🐜 [PATH CHECK] Nông dân khởi tạo xong Job: ", current_job, " | Path size: ", current_path.size())

# THÊM ĐOẠN NÀY VÀO TRONG HÀM _draw() CỦA FILE worker.gd
func _draw() -> void:
	draw_circle(Vector2.ZERO, agent_radius, agent_color)
	
	# Hiển thị số lượng tài nguyên đang mang theo
	var carrying_text = ""
	var text_color = Color.WHITE
	if carried_wood > 0:
		carrying_text = str(carried_wood) + " gỗ"
		text_color = Color.SADDLE_BROWN
	elif carried_gold > 0:
		carrying_text = str(carried_gold) + " vàng"
		text_color = Color.GOLD
		
	if carrying_text != "":
		draw_string(ThemeDB.fallback_font, Vector2(8, 4), carrying_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, text_color)

# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE worker.gd
func _physics_process(delta: float) -> void:
	queue_redraw() 
	
	match current_job:
		Job.NONE: velocity = Vector2.ZERO
		Job.GOLD_MINER: _process_gold_miner_job(delta)
		Job.WOOD_CHOPPER: _process_wood_chopper_job(delta)
		Job.BUILDER: _process_builder_job(delta)
		Job.SCOUT: _process_scout_job(delta)

	# Để Godot lo việc di chuyển và trượt dọc theo vật cản (Đá/Tường)
	move_and_slide()

	# ==========================================
	# 1. XỬ LÝ NỘP TÀI NGUYÊN (Chỉ kiểm tra chạm Nhà chính)
	# ==========================================
	if current_state == State.RETURNING_TO_BASE and get_slide_collision_count() > 0:
		for i in range(get_slide_collision_count()):
			var collider = get_slide_collision(i).get_collider()
			if collider and collider.is_in_group("main_base"):
				print("🏠 [NÔNG DÂN] Đã về tới cửa Nhà chính! Nộp đồ.")
				velocity = Vector2.ZERO
				deposit_resources()
				break # Nộp xong thì thoát vòng lặp kiểm tra

	# ==========================================
	# 2. HỆ THỐNG CHỐNG KẸT THÔNG MINH (Stuck Detection)
	# ==========================================
	# Nếu AI đang ra lệnh di chuyển (velocity > 0)
	# NHƯNG nhân vật không thể nhích lên được (get_real_velocity < 5.0) -> Chắc chắn đang kẹt cứng!
	if current_state in [State.MOVING_TO_TARGET, State.MOVING_TO_BASE_FOR_WOOD, State.RETURNING_TO_BASE, State.WORKING]:
		if velocity.length() > 0.0 and get_real_velocity().length() < 5.0:
			print("⚠️ [NÔNG DÂN] Kẹt góc/Viền map! Hủy đường đi hiện tại để AI tính lại.")
			velocity = Vector2.ZERO
			current_path.clear()
			current_state = State.IDLE				
func request_path(target_pos: Vector2) -> void:
	if grid_manager:
		current_path = grid_manager.get_path_for_ant(global_position, target_pos)
		
		# BẰNG CHỨNG CHUẨN XÁC: Chỉ log ra khi thực sự xin đường mà bị rỗng
		if current_path.size() == 0:
			print("🚨 [LỖI TÌM ĐƯỜNG] Nông dân tại ", global_position, " KHÔNG THỂ tìm thấy đường đến: ", target_pos)

# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE worker.gd
# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE worker.gd
func move_along_path() -> void:
	if current_path.size() == 0:
		velocity = Vector2.ZERO
		return
		
	var target_point = current_path[0]
	var dist = global_position.distance_to(target_point)
	
	if dist < 4.0:
		global_position = target_point 
		current_path.pop_front()
		velocity = Vector2.ZERO
	else:
		velocity = global_position.direction_to(target_point) * speed
		move_and_slide()
		
		# BẢN VÁ LỖI VẬT LÝ: Tự động trượt lách khi bị cạ vào tường
		if get_slide_collision_count() > 0:
			var collision = get_slide_collision(0)
			if collision:
				# Dội ngược lại theo hướng bật nảy (Normal) của bức tường 2 pixel để lách qua
				global_position += collision.get_normal() * 2.0

# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE worker.gd
func _process_scout_job(_delta: float) -> void:
	match current_state:
		State.IDLE:
			var random_target = global_position + Vector2(randf_range(-1000, 1000), randf_range(-1000, 1000))
			
			# FIX BUG 1: Ép mục tiêu không bao giờ được vượt quá viền bản đồ (-1950 đến 1950)
			random_target.x = clamp(random_target.x, -1950, 1950)
			random_target.y = clamp(random_target.y, -1950, 1950)
			
			request_path(random_target)
			if current_path.size() > 0: current_state = State.MOVING_TO_TARGET
		State.MOVING_TO_TARGET:
			move_along_path()
			_scan_for_resources()
			if current_path.size() == 0: current_state = State.IDLE
		_:
			current_state = State.IDLE

func _scan_for_resources() -> void:
	var hidden_nodes = get_tree().get_nodes_in_group("hidden_resources")
	for node in hidden_nodes:
		if is_instance_valid(node) and global_position.distance_to(node.global_position) < vision_radius:
			if node.has_method("discover"): node.discover()

func _process_gold_miner_job(_delta: float) -> void:
	match current_state:
		State.IDLE: find_gold_node()
		State.MOVING_TO_TARGET:
			if is_instance_valid(target_gold_node) and global_position.distance_to(target_gold_node.global_position) < 35.0:
				current_path.clear()
				start_harvesting()
			else:
				move_along_path()
				if current_path.size() == 0: current_state = State.IDLE
		State.WORKING: velocity = Vector2.ZERO
		State.RETURNING_TO_BASE:
			if main_base and global_position.distance_to(main_base.global_position) < 60.0:
				current_path.clear()
				deposit_resources()
			else:
				move_along_path()
				if current_path.size() == 0: current_state = State.IDLE

func find_gold_node() -> void:
	var nodes = get_tree().get_nodes_in_group("gold_nodes")
	if nodes.size() > 0:
		target_gold_node = nodes[0] as Area2D
		if target_gold_node:
			request_path(target_gold_node.global_position)
			current_state = State.MOVING_TO_TARGET
	else:
		current_state = State.IDLE

# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE worker.gd
func _process_wood_chopper_job(_delta: float) -> void:
	match current_state:
		State.IDLE:
			var nodes = get_tree().get_nodes_in_group("wood_nodes")
			var nearest_node = null
			var min_dist = INF
			
			# FIX BUG 1: Quét tất cả mỏ gỗ, so sánh khoảng cách để lấy mỏ gần nhất
			for node in nodes:
				if is_instance_valid(node) and "current_wood" in node and node.current_wood > 0:
					var dist = global_position.distance_to(node.global_position)
					if dist < min_dist:
						min_dist = dist
						nearest_node = node
						
			if nearest_node:
				target_wood_node = nearest_node
				# BẰNG CHỨNG LOG: Báo cáo chính xác mỏ nào được chốt và cách bao xa
				#print("🪓 [AI GỖ] Kiến chốt mỏ gần nhất tại: ", nearest_node.global_position, " | Khoảng cách: ", min_dist)
				request_path(target_wood_node.global_position)
				current_state = State.MOVING_TO_TARGET
			else:
				target_wood_node = null
				
		State.MOVING_TO_TARGET:
			# NẾU mỏ gỗ mục tiêu đột nhiên bốc hơi (bị con khác chặt hết) -> Quay về IDLE tìm mỏ mới
			if not is_instance_valid(target_wood_node):
				#print("🚨 [AI GỖ] Mỏ gỗ mục tiêu đã cạn/biến mất! Chuyển hướng tìm mỏ khác...")
				current_path.clear()
				current_state = State.IDLE
				return
				
			if global_position.distance_to(target_wood_node.global_position) < 35.0:
				current_path.clear()
				start_harvesting()
			else:
				move_along_path()
				if current_path.size() == 0: current_state = State.IDLE
				
		State.WORKING:
			if not is_instance_valid(target_wood_node):
				harvest_timer.stop()
				current_state = State.IDLE
				
		State.RETURNING_TO_BASE:
			if main_base and global_position.distance_to(main_base.global_position) < 75.0:
				current_path.clear()
				deposit_resources()
			else:
				move_along_path()
				if current_path.size() == 0: current_state = State.IDLE
func find_wood_node() -> void:
	var nodes = get_tree().get_nodes_in_group("wood_nodes")
	if nodes.size() > 0:
		target_wood_node = nodes[0] as Area2D
		if target_wood_node:
			request_path(target_wood_node.global_position)
			current_state = State.MOVING_TO_TARGET
	else:
		current_state = State.IDLE

# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE worker.gd
# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE worker.gd
func _process_builder_job(delta: float) -> void:
	match current_state:
		State.IDLE:
			find_nearest_foundation()
		State.MOVING_TO_BASE_FOR_WOOD:
			# ĐÃ SỬA: Tăng khoảng cách lên 75.0 để bao trùm được các góc chéo của Nhà chính
			if main_base and global_position.distance_to(main_base.global_position) < 75.0:
				current_path.clear()
				if main_base.has_method("use_resource") and main_base.use_resource("wood", 10):
					has_wood_for_build = true
					carried_wood = 10
					if is_instance_valid(target_foundation):
						request_path(target_foundation.global_position)
						current_state = State.MOVING_TO_TARGET
					else:
						current_state = State.IDLE
				else:
					velocity = Vector2.ZERO
			else:
				move_along_path()
				if current_path.size() == 0:
					# BẰNG CHỨNG LOG & FIX: Bỏ cuộc vì kẹt đường thì PHẢI nhả móng ra cho con khác làm!
					print("🚨 [LỖI BUILDER] Hủy lấy gỗ vì không tới được Base! Nhả móng: ", target_foundation)
					if is_instance_valid(target_foundation):
						target_foundation.is_wood_assigned = false
						target_foundation = null
					current_state = State.IDLE
					
		State.MOVING_TO_TARGET:
			if is_instance_valid(target_foundation) and global_position.distance_to(target_foundation.global_position) < 35.0:
				current_path.clear()
				current_state = State.WORKING
			else:
				move_along_path()
				if current_path.size() == 0:
					print("🚨 [LỖI BUILDER] Kẹt đường đến móng nhà! Nhả móng: ", target_foundation)
					if is_instance_valid(target_foundation):
						target_foundation.is_wood_assigned = false
						target_foundation = null
					current_state = State.IDLE
					
		State.WORKING:
			velocity = Vector2.ZERO
			if is_instance_valid(target_foundation):
				target_foundation.build(build_speed * delta)
			else:
				has_wood_for_build = false
				carried_wood = 0
				current_state = State.IDLE

# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE worker.gd
func find_nearest_foundation() -> void:
	var nodes = get_tree().get_nodes_in_group("foundations")
	var valid_foundations: Array[Area2D] = []
	
	for n in nodes:
		var f = n if n is Area2D else (n.get_parent() if n.get_parent() is Area2D else null)
		# CHỈ TÌM NHỮNG MÓNG CHƯA CÓ AI NHẬN XÂY
		if f and "is_wood_assigned" in f and f.is_wood_assigned == false:
			valid_foundations.append(f)
			
	if valid_foundations.size() > 0:
		var nearest = valid_foundations[0]
		var min_dist = global_position.distance_to(nearest.global_position)
		for f in valid_foundations:
			var dist = global_position.distance_to(f.global_position)
			if dist < min_dist:
				min_dist = dist
				nearest = f
				
		target_foundation = nearest
		# KHÓA MÓNG LẠI: Đánh dấu đã có thầu, người khác cấm tranh!
		target_foundation.is_wood_assigned = true 
		
		if not has_wood_for_build:
			if main_base:
				var spawn_pt = main_base.get_node_or_null("SpawnPoint")
				var target_pt = spawn_pt.global_position if spawn_pt else main_base.global_position
				request_path(target_pt)
				current_state = State.MOVING_TO_BASE_FOR_WOOD
		else:
			request_path(target_foundation.global_position)
			current_state = State.MOVING_TO_TARGET
	else:
		current_state = State.IDLE

func start_harvesting() -> void:
	current_state = State.WORKING
	velocity = Vector2.ZERO
	harvest_timer.start()

func _on_harvest_finished() -> void:
	if current_job == Job.GOLD_MINER and is_instance_valid(target_gold_node):
		if target_gold_node.has_method("harvest"):
			# Tính khoảng trống còn lại trong túi để không lấy lố
			var space_left = Global.worker_carry_cap - carried_gold
			var amt_to_harvest = min(Global.worker_harvest_amt, space_left)
			
			var amt = target_gold_node.harvest(amt_to_harvest)
			carried_gold += amt # Cộng dồn thay vì gán đè
			print("⛏️ [NÔNG DÂN] Đã đào ", amt, " Vàng. Túi hiện tại: ", carried_gold, "/", Global.worker_carry_cap)
			
			# Kiểm tra xem đầy túi chưa hoặc mỏ đã cạn chưa
			if carried_gold >= Global.worker_carry_cap or not is_instance_valid(target_gold_node):
				_return_to_base()
			else:
				harvest_timer.start() # Chưa đầy thì ở lại đào tiếp
				
	elif current_job == Job.WOOD_CHOPPER and is_instance_valid(target_wood_node):
		if target_wood_node.has_method("harvest"):
			# Logic tương tự cho việc chặt Gỗ
			var space_left = Global.worker_carry_cap - carried_wood
			var amt_to_harvest = min(Global.worker_harvest_amt, space_left)
			
			var amt = target_wood_node.harvest(amt_to_harvest)
			carried_wood += amt
			
			if carried_wood >= Global.worker_carry_cap or not is_instance_valid(target_wood_node):
				_return_to_base()
			else:
				harvest_timer.start() # Chưa đầy thì chặt tiếp
func _return_to_base() -> void:
	if main_base:
		var spawn_pt = main_base.get_node_or_null("SpawnPoint")
		var target_pt = spawn_pt.global_position if spawn_pt else main_base.global_position
		
		#print("🪵 [BUG 2 DEBUG] Kiến đã chặt xong! Đang xin đường về nhà tại: ", target_pt)
		request_path(target_pt)

		
		current_state = State.RETURNING_TO_BASE
	else:
		current_state = State.IDLE

func deposit_resources() -> void:
	if main_base and main_base.has_method("add_resource"):
		if carried_gold > 0:
			main_base.add_resource("gold", carried_gold)
			carried_gold = 0
		if carried_wood > 0:
			main_base.add_resource("wood", carried_wood)
			carried_wood = 0
			
	current_state = State.IDLE

func set_job(new_job: Job) -> void:
	current_job = new_job
	match new_job:
		Job.WOOD_CHOPPER:
			agent_color = Color.CYAN
		Job.BUILDER:
			agent_color = Color.YELLOW
		Job.GOLD_MINER:
			agent_color = Color.GOLD
		Job.SCOUT:
			agent_color = Color.PINK
		_:
			agent_color = Color.WHITE
			
	# BẢN VÁ LỖI LOGIC: Kiểm tra 2 tay có đang cầm đồ hay không?
	if carried_gold > 0 or carried_wood > 0:
		print("🧑‍🌾 [NÔNG DÂN] Đổi việc sang ", new_job, " nhưng tay đang cầm (Vàng: ", carried_gold, ", Gỗ: ", carried_wood, "). Về cất trước!")
		_return_to_base() # Bắt buộc đi về nhà trả đồ
	else:
		current_state = State.IDLE # Xóa việc cũ, rảnh tay để nhận lệnh tìm mỏ mới
		current_path.clear()
func evaluate_job() -> void:
	current_state = State.IDLE
	match current_job:
		Job.GOLD_MINER: find_gold_node()
		Job.WOOD_CHOPPER: find_wood_node()
		Job.BUILDER: find_nearest_foundation()
		Job.SCOUT: current_state = State.IDLE
