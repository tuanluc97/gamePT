extends CanvasLayer

@onready var btn_wall: Button = $HBoxContainer/BtnWall
@onready var btn_tower: Button = $HBoxContainer/BtnTower
@onready var btn_trap: Button = $HBoxContainer/BtnTrap

func _ready() -> void:
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

func _on_build_trap() -> void:
	var grid = get_tree().get_nodes_in_group("grid_manager")
	if grid.size() > 0 and grid[0].has_method("select_building_type"):
		grid[0].select_building_type("trap")
