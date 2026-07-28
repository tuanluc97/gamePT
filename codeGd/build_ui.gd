extends CanvasLayer

@onready var btn_wall: Button = $HBoxContainer/BtnWall
@onready var btn_tower: Button = $HBoxContainer/BtnTower
@onready var btn_trap: Button = $HBoxContainer/BtnTrap

func _ready() -> void:
	var hbox = $HBoxContainer
	if hbox:
		# Lấy vị trí Y hiện tại và trừ đi 30px để đẩy nó lên trên
		hbox.position.y -= 30.0
		
	# Kết nối sự kiện bấm nút
	btn_wall.pressed.connect(_on_build_wall)
	btn_tower.pressed.connect(_on_build_tower)
	btn_trap.pressed.connect(_on_build_trap)

func _on_build_wall() -> void:
	var grid = get_tree().get_nodes_in_group("grid_manager")
	if grid.size() > 0 and grid[0].has_method("select_building_type"):
		grid[0].select_building_type("wall")

func _on_build_tower() -> void:
	var grid = get_tree().get_nodes_in_group("grid_manager")
	if grid.size() > 0 and grid[0].has_method("select_building_type"):
		grid[0].select_building_type("tower")

# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE build_ui.gd
func _on_build_trap() -> void:
	print("🔘 [UI DEBUG] Đã bấm nút Xây Bẫy trên màn hình!")
	var grid = get_tree().get_nodes_in_group("grid_manager")
	if grid.size() > 0 and grid[0].has_method("select_building_type"):
		grid[0].select_building_type("trap")
	else:
		print("🚨 [UI LỖI] Không tìm thấy grid_manager để gửi lệnh!")
