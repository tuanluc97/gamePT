extends CharacterBody2D

enum MonsterType { FAST, TANK }

var monster_type: MonsterType = MonsterType.FAST
var speed: float = 140.0
var max_hp: float = 30.0
var current_hp: float = 30.0
var attack_damage: float = 1.0
var attack_timer: float = 0.0
var main_base: Node2D = null
var grid_manager: Node2D = null
var current_path: Array[Vector2] = []
var path_update_timer: float = 0.0
var trap_timer: float = 0.0
var current_trap: Node2D = null

@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	add_to_group("monsters")
	
	var bases = get_tree().get_nodes_in_group("main_base")
	if bases.size() > 0: main_base = bases[0]
	
	await get_tree().physics_frame
	var grids = get_tree().get_nodes_in_group("grid_manager")
	if grids.size() > 0: grid_manager = grids[0]
	
	_request_path_to_base()

# Cấu hình chỉ số cho từng loại quái vật
# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE monster.gd
# CHỈ SỬA 2 HÀM NÀY TRONG FILE monster.gd

func setup(type: int) -> void:
	if not is_node_ready():
		await ready
		
	monster_type = type as MonsterType
	if color_rect: color_rect.visible = false 
	
	if monster_type == MonsterType.FAST:
		speed = 150.0
		max_hp = 30.0
		attack_damage = 1.0 # BẢN VÁ: Quái nhanh dame 1
		scale = Vector2(0.8, 0.8)
	elif monster_type == MonsterType.TANK:
		speed = 60.0
		max_hp = 120.0
		attack_damage = 2.0 # BẢN VÁ: Quái trâu dame 2
		scale = Vector2(1.3, 1.3)
		
	current_hp = max_hp
	queue_redraw()

func _move_along_path() -> void:
	if current_path.size() == 0:
		velocity = Vector2.ZERO
		return
		
	var target_point = current_path[0]
	var dist = global_position.distance_to(target_point)
	
	# FIX BUG 1: Tăng khoảng cách bắt mốc lên 25px để bầy quái không cần dẫm lên đúng 1 pixel
	if dist < 25.0:
		current_path.pop_front()
	else:
		velocity = global_position.direction_to(target_point) * speed
		move_and_slide()
		
		# BẢN VÁ VẬT LÝ: Nếu bầy đàn chen chúc đè lên nhau, tự động tản dạt ra xung quanh
		if get_slide_collision_count() > 0:
			var collision = get_slide_collision(0)
			if collision:
				global_position += collision.get_normal() * 2.0
func _physics_process(delta: float) -> void:
	queue_redraw() 
	
	# Xử lý hiệu ứng bị kẹt trong bẫy
	if trap_timer > 0:
		trap_timer -= delta
		if trap_timer <= 0:
			if is_instance_valid(current_trap) and current_trap.has_method("release_monster"):
				current_trap.release_monster(self)
			set_meta("is_trapped", false)
			
			# Hết thời gian kẹt, bật lại va chạm vật lý để đi tiếp
			collision_layer = 1
			collision_mask = 1
			print("💨 [QUÁI VẬT] Đã thoát khỏi bẫy!")
		return # Bỏ qua di chuyển nếu đang bị kẹt
	
	path_update_timer += delta
	if path_update_timer >= 1.5:
		path_update_timer = 0.0
		_request_path_to_base()
		
	_move_along_path()
	
	# === LOGIC TẤN CÔNG NHÀ CHÍNH (Giữ nguyên) ===
	if main_base and is_instance_valid(main_base):
		if global_position.distance_to(main_base.global_position) < 80.0:
			attack_timer += delta
			if attack_timer >= 1.0:
				attack_timer = 0.0
				if main_base.has_method("take_damage"):
					main_base.take_damage(attack_damage)
					print("⚔️ [QUÁI VẬT] Vừa cắn nhà chính! Gây sát thương: ", attack_damage)

# Hàm nhận sát thương
func take_damage(amount: float) -> void:
	current_hp -= amount
	if current_hp <= 0:
		print("💀 [QUÁI VẬT] 1 quái vật đã bị tiêu diệt!")
		queue_free()
		
# THÊM HÀM MỚI NÀY VÀO CUỐI FILE monster.gd
func _draw() -> void:
	# 1. VẼ NGOẠI HÌNH QUÁI VẬT
	if monster_type == MonsterType.FAST:
		# Vẽ Tam giác màu Vàng (Gồm 3 đỉnh: Trên, Dưới Phải, Dưới Trái)
		var points = PackedVector2Array([Vector2(0, -15), Vector2(15, 15), Vector2(-15, 15)])
		var colors = PackedColorArray([Color.YELLOW])
		draw_polygon(points, colors)
	else:
		# Vẽ Hình vuông màu Đỏ
		var rect = Rect2(-15, -15, 30, 30)
		draw_rect(rect, Color.RED)
		
	# 2. VẼ CHỈ SỐ MÁU (HP) Ở DƯỚI CHÂN
	var hp_text = str(current_hp) + "/" + str(max_hp)
	# Tọa độ Vector2(0, 25) giúp đẩy chữ xuống dưới chân quái vật
	draw_string(ThemeDB.fallback_font, Vector2(0, 25), hp_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.WHITE)
func _request_path_to_base() -> void:
	if grid_manager and main_base:
		if grid_manager.has_method("get_path_for_monster"):
			current_path = grid_manager.get_path_for_monster(global_position, main_base.global_position)
		else:
			current_path = grid_manager.get_path_for_ant(global_position, main_base.global_position)

# 4. THÊM HÀM MỚI NÀY VÀO CUỐI FILE monster.gd
func get_trapped(duration: float, trap_node: Node2D) -> void:
	trap_timer = duration
	current_trap = trap_node
	set_meta("is_trapped", true)
	# Mẹo nhỏ: Tắt va chạm vật lý để quái thứ 4 (khi bẫy đầy) có thể bước đi xuyên qua đầu quái đang kẹt
	collision_layer = 0
	collision_mask = 0
