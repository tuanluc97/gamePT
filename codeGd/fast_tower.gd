extends StaticBody2D

var damage: float = 5.0
var fire_rate: float = 0.2 # Bắn 5 phát / giây (Rất nhanh)
var attack_range: float = 150.0 # Tầm trung
var current_target: Node2D = null

@onready var fire_timer: Timer = $FireTimer

# Biến dùng để vẽ tia Laser
var draw_laser: bool = false
var laser_target_pos: Vector2 = Vector2.ZERO
var laser_timer: float = 0.0

func _ready() -> void:
	add_to_group("walls") # Cho quái vật biết đây là vật cản
	fire_timer.wait_time = fire_rate
	fire_timer.timeout.connect(_shoot)
	fire_timer.start()

func _physics_process(delta: float) -> void:
	# Xóa tia laser sau 0.05 giây để tạo hiệu ứng chớp nháy
	if draw_laser:
		laser_timer -= delta
		if laser_timer <= 0:
			draw_laser = false
		queue_redraw()

func _shoot() -> void:
	if not is_instance_valid(current_target) or global_position.distance_to(current_target.global_position) > attack_range:
		_find_target()
	
	if is_instance_valid(current_target):
		if current_target.has_method("take_damage"):
			current_target.take_damage(damage)
			# Vẽ tia laser nhắm thẳng vào quái
			laser_target_pos = current_target.global_position - global_position
			draw_laser = true
			laser_timer = 0.05
			queue_redraw()
			# BẰNG CHỨNG LOG: Bắn trúng quái
			#print("⚡ [THÁP CANH] Bắn Laser trúng quái tại: ", current_target.global_position)

func _find_target() -> void:
	current_target = null
	var monsters = get_tree().get_nodes_in_group("monsters")
	var min_dist = attack_range
	for m in monsters:
		if is_instance_valid(m):
			var dist = global_position.distance_to(m.global_position)
			if dist <= min_dist:
				min_dist = dist
				current_target = m

func _draw() -> void:
	# Thiết kế tối giản: Tháp là một hình Lục giác / Thoi màu Xanh Dương
	var points = PackedVector2Array([Vector2(0, -16), Vector2(16, 0), Vector2(0, 16), Vector2(-16, 0)])
	draw_polygon(points, PackedColorArray([Color.CORNFLOWER_BLUE]))
	
	if draw_laser:
		draw_line(Vector2.ZERO, laser_target_pos, Color.CYAN, 2.0) # Laser màu Cyan
