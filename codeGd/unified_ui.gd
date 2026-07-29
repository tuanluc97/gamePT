extends CanvasLayer

@onready var bottom_panel: Control = $BottomPanel
@onready var toggle_btn: Button = $ToggleBtn

# Tài nguyên (Góc trên trái)
@onready var gold_label: Label = $ResourcePanel/HBoxContainer/GoldLabel
@onready var wood_label: Label = $ResourcePanel/HBoxContainer/WoodLabel

# Bảng Log (Cột Trái của BottomPanel)
@onready var log_text: RichTextLabel = $BottomPanel/MainHBox/LogVBox/LogText

# Các Menu Ngữ cảnh (Cột Giữa)
@onready var default_menu: VBoxContainer = $BottomPanel/MainHBox/ContextVBox/DefaultMenu
@onready var base_menu: VBoxContainer = $BottomPanel/MainHBox/ContextVBox/BaseMenu
@onready var tower_menu: VBoxContainer = $BottomPanel/MainHBox/ContextVBox/TowerMenu
@onready var hero_menu: VBoxContainer = $BottomPanel/MainHBox/ContextVBox/HeroMenu

# Các nút
@onready var btn_wall: Button = default_menu.get_node("BuildHBox/BtnWall")
@onready var btn_tower: Button = default_menu.get_node("BuildHBox/BtnTower")
@onready var btn_trap: Button = default_menu.get_node("BuildHBox/BtnTrap")
@onready var buy_worker_btn: Button = base_menu.get_node("BuyWorkerBtn")
@onready var hp_label: Label = base_menu.get_node("BaseHPLabel")

func _ready() -> void:
	add_to_group("unified_ui")
	_adjust_panel_position()
	
	switch_context("default") # Khởi động ở Menu Xây Dựng mặc định
	
	# Kết nối sự kiện nút bấm
	toggle_btn.pressed.connect(_on_toggle_pressed)
	btn_wall.pressed.connect(func(): _select_build("wall"))
	btn_tower.pressed.connect(func(): _select_build("tower"))
	btn_trap.pressed.connect(func(): _select_build("trap"))
	buy_worker_btn.pressed.connect(_on_buy_worker_pressed)
	
	Global.log_event.connect(_on_new_log)
	
	# BẢN VÁ TÀI NGUYÊN: Tự động kết nối tới Nhà Chính để nhận cập nhật Vàng/Gỗ
	call_deferred("_connect_to_main_base")
# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE unified_ui.gd
func switch_context(menu_type: String, info_title: String = "", info_details: String = "") -> void:
	if default_menu: default_menu.hide()
	if base_menu: base_menu.hide()
	if tower_menu: tower_menu.hide()
	if hero_menu: hero_menu.hide()
	
	# BẢN VÁ LỖI 1: Luôn tắt chế độ xây dựng trên GridMap khi chuyển sang ngữ cảnh khác
	var grid = get_tree().get_nodes_in_group("grid_manager")
	if grid.size() > 0 and grid[0].has_method("select_building_type"):
		grid[0].select_building_type("none")
		
	match menu_type:
		"base":
			if base_menu: base_menu.show()
			print("🎛️ [UI] Mở Menu Căn Cứ")
		"tower", "info":
			if tower_menu:
				tower_menu.show()
				var info_label = tower_menu.get_node_or_null("TowerInfoLabel")
				if info_label and info_title != "":
					info_label.text = info_title + "\n" + info_details
			print("🎛️ [UI] Mở Bảng Thông Tin: ", info_title)
		"hero":
			if hero_menu: hero_menu.show()
			print("🎛️ [UI] Mở Menu Hero")
		_:
			if default_menu: default_menu.show()
			print("🎛️ [UI] Trở về Menu Xây Dựng Mặc Định")
	
func update_buy_queue(queue_count: int) -> void:
	if buy_worker_btn:
		buy_worker_btn.text = "Mua Kiến (10 Vàng) - Hàng chờ: " + str(queue_count)
		
func _adjust_panel_position() -> void:
	# BẢN VÁ UI: Nếu màn hình bị co, gọi Deferred để lấy đúng kích thước thật
	call_deferred("_do_adjust_position")

func _connect_to_main_base() -> void:
	var bases = get_tree().get_nodes_in_group("main_base")
	if bases.size() > 0:
		var base_node = bases[0]
		if not base_node.gold_changed.is_connected(update_gold):
			base_node.gold_changed.connect(update_gold)
		if not base_node.wood_changed.is_connected(update_wood):
			base_node.wood_changed.connect(update_wood)
			
		# Lấy giá trị ban đầu gán thẳng lên UI góc trên trái
		if "gold_storage" in base_node: update_gold(base_node.gold_storage)
		if "wood_storage" in base_node: update_wood(base_node.wood_storage)
		if "current_hp" in base_node: update_base_hp(base_node.current_hp, Global.base_hp)
		print("🔗 [UI HỢP NHẤT] Đã kết nối tín hiệu Vàng/Gỗ với Nhà Chính thành công!")
		
func _do_adjust_position() -> void:
	var screen_height = get_viewport().get_visible_rect().size.y
	if bottom_panel:
		bottom_panel.global_position.y = screen_height - bottom_panel.size.y
		toggle_btn.global_position.y = bottom_panel.global_position.y - 30.0

func _on_toggle_pressed() -> void:
	bottom_panel.visible = !bottom_panel.visible
	toggle_btn.text = "Mở Giao Diện" if not bottom_panel.visible else "Ẩn Giao Diện"

func _select_build(type: String) -> void:
	var grid = get_tree().get_nodes_in_group("grid_manager")
	if grid.size() > 0 and grid[0].has_method("select_building_type"):
		grid[0].select_building_type(type)
		print("🧰 [UI] Đã phát lệnh xây: ", type)

func _on_buy_worker_pressed() -> void:
	var bases = get_tree().get_nodes_in_group("main_base")
	if bases.size() > 0 and bases[0].has_method("_on_buy_pressed"):
		bases[0]._on_buy_pressed()

func update_gold(amount: int) -> void:
	if gold_label: gold_label.text = "Vàng: " + str(amount)

func update_wood(amount: int) -> void:
	if wood_label: wood_label.text = "Gỗ: " + str(amount)

func update_base_hp(current_hp: float, max_hp: float) -> void:
	if hp_label: hp_label.text = "HP Căn Cứ: " + str(int(current_hp)) + "/" + str(int(max_hp))



func _on_new_log(type: String, msg: String) -> void:
	var color_code = "white"
	match type:
		"alert": color_code = "red"
		"success": color_code = "green"
		"build": color_code = "yellow"
		"system": color_code = "cyan"
		
	if log_text:
		log_text.text += "\n[color=" + color_code + "]" + msg + "[/color]"
		log_text.scroll_to_line(log_text.get_line_count() - 1)
