extends Area2D

var trapped_monsters: Array[Node2D] = []
var max_capacity: int = 3

func _ready() -> void:
	add_to_group("traps")
	body_entered.connect(_on_body_entered)

func _process(_delta: float) -> void:
	# Dọn dẹp quái đã chết khỏi mảng
	for i in range(trapped_monsters.size() - 1, -1, -1):
		if not is_instance_valid(trapped_monsters[i]):
			trapped_monsters.remove_at(i)
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("monsters"):
		# Nếu hố chưa đầy và con quái này chưa bị kẹt
		if trapped_monsters.size() < max_capacity and not body.get_meta("is_trapped", false):
			trapped_monsters.append(body)
			
			print("🕳️ [BẪY] 1 Quái vật đã sập bẫy! Đang chứa: ", trapped_monsters.size(), "/", max_capacity)
			
			if body.has_method("take_damage"):
				body.take_damage(10.0) # Trừ 10 máu
			
			if body.has_method("get_trapped"):
				body.get_trapped(5.0, self) # Kẹt 5 giây

func release_monster(body: Node2D) -> void:
	if body in trapped_monsters:
		trapped_monsters.erase(body)

func _draw() -> void:
	# Thiết kế tối giản: Hố bẫy màu đen, và vẽ các chấm đỏ báo hiệu quái bị kẹt bên trong
	draw_rect(Rect2(-14, -14, 28, 28), Color.BLACK)
	for i in range(trapped_monsters.size()):
		draw_circle(Vector2(-8 + i * 8, 0), 3.0, Color.RED)
