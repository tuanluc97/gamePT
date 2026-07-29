extends Node2D

var grid_size: float = 32.0
var current_tool: String = "base"
var camera: Camera2D
var cam_speed: float = 600.0

var map_data: Dictionary = {
	"map_name": "NewMap",
	"map_width": 2000,
	"map_height": 2000,
	"bases": [], "spawns": [], "resources": [], "obstacles": []
}

# Tham chiếu giao diện
var name_input: LineEdit
var w_input: SpinBox
var h_input: SpinBox

func _ready() -> void:
	# Tạo Camera di chuyển tự do
	camera = Camera2D.new()
	add_child(camera)
	
	# Nhận dữ liệu nếu Load từ Menu
	if Global.get("map_to_edit") != null and Global.map_to_edit != "":
		var loaded = MapDataHandler.load_map(Global.map_to_edit)
		if not loaded.is_empty():
			map_data = loaded
			print("🗺️ [MAP EDITOR] Đã load map: ", Global.map_to_edit)
			
	_build_editor_ui()

# Xử lý di chuyển Camera bằng WASD / Mũi tên
func _process(delta: float) -> void:
	var dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dir != Vector2.ZERO:
		camera.position += dir * cam_speed * delta

# UI cấu hình Map
func _build_editor_ui() -> void:
	var canvas = CanvasLayer.new()
	add_child(canvas)
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	canvas.add_child(panel)
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# Hàng 1: Cài đặt thông số Map
	var top_row = HBoxContainer.new()
	vbox.add_child(top_row)
	
	var lbl_name = Label.new(); lbl_name.text = " Tên Map:"
	top_row.add_child(lbl_name)
	name_input = LineEdit.new()
	name_input.text = map_data["map_name"]
	name_input.custom_minimum_size.x = 150
	top_row.add_child(name_input)
	
	var lbl_w = Label.new(); lbl_w.text = " Rộng:"
	top_row.add_child(lbl_w)
	w_input = SpinBox.new(); w_input.max_value = 10000; w_input.step = 32; w_input.min_value = 320
	w_input.value = map_data["map_width"]
	top_row.add_child(w_input)
	
	var lbl_h = Label.new(); lbl_h.text = " Cao:"
	top_row.add_child(lbl_h)
	h_input = SpinBox.new(); h_input.max_value = 10000; h_input.step = 32; h_input.min_value = 320
	h_input.value = map_data["map_height"]
	top_row.add_child(h_input)
	
	var save_btn = Button.new()
	save_btn.text = "💾 LƯU MAP"
	save_btn.modulate = Color.GREEN
	save_btn.pressed.connect(_save_map_from_ui)
	top_row.add_child(save_btn)
	
	var exit_btn = Button.new()
	exit_btn.text = "❌ Về Menu"
	exit_btn.modulate = Color.RED
	exit_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/menu.tscn"))
	top_row.add_child(exit_btn)

	# Hàng 2: Nút công cụ (Bút vẽ)
	var tools_row = HBoxContainer.new()
	vbox.add_child(tools_row)
	var tools = ["base", "gold", "wood", "spawn", "obstacle", "hero"]
	for t in tools:
		var btn = Button.new()
		btn.text = "✏️ Đặt " + t
		btn.pressed.connect(func(): current_tool = t; print("🧰 [EDITOR] Chọn công cụ: ", t))
		tools_row.add_child(btn)

# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE map_editor.gd
func _save_map_from_ui() -> void:
	map_data["map_name"] = name_input.text
	
	# BẢN VÁ LỖI "NỬA Ô": Bắt buộc tổng chiều rộng/cao phải là bội số của 64 (grid_size * 2)
	# Để khi sinh Map chia đôi ra tọa độ (offset_x), nó sẽ chia hết tuyệt đối cho 32!
	var step = grid_size * 2.0
	var normalized_w = max(320, int(round(w_input.value / step)) * int(step))
	var normalized_h = max(320, int(round(h_input.value / step)) * int(step))
	
	w_input.value = normalized_w
	h_input.value = normalized_h
	
	map_data["map_width"] = normalized_w
	map_data["map_height"] = normalized_h
	
	MapDataHandler.save_map(name_input.text, map_data)
	print("📐 [MAP EDITOR] Đã chuẩn hóa kích thước Map tránh kẹt viền: ", normalized_w, "x", normalized_h)
	queue_redraw()

# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE map_editor.gd
# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE map_editor.gd
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_global_mouse_position()
		var snap_pos: Vector2
		
		if current_tool == "base":
			snap_pos = (mouse_pos / grid_size).round() * grid_size
		else:
			snap_pos = (mouse_pos / grid_size).floor() * grid_size + Vector2(grid_size / 2.0, grid_size / 2.0)
		
		var w = int(w_input.value) if w_input else map_data["map_width"]
		var h = int(h_input.value) if h_input else map_data["map_height"]
		
		# BẢN VÁ: Giới hạn click dựa trên gốc tọa độ mới (0,0) đến (w,h)
		if snap_pos.x < 0 or snap_pos.x > w or snap_pos.y < 0 or snap_pos.y > h: 
			print("⚠️ [MAP EDITOR] Click ngoài bản đồ: ", snap_pos)
			return
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			_remove_item_at(snap_pos)
			_place_item(snap_pos)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_remove_item_at(snap_pos)
			print("🗑️ [EDITOR] Đã xóa vật thể tại: ", snap_pos)
		queue_redraw()

# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE map_editor.gd
func _draw() -> void:
	var w = int(w_input.value) if w_input else map_data.get("map_width", 2000)
	var h = int(h_input.value) if h_input else map_data.get("map_height", 2000)
	
	# BẢN VÁ TOÁN HỌC: Vẽ biên giới Map BẮT ĐẦU TỪ GÓC (0,0) đi xuống góc (w, h)
	draw_rect(Rect2(0, 0, w, h), Color.RED, false, 2.0)
	
	# Vẽ lưới nền bắt đầu từ 0
	for x in range(0, w + 1, int(grid_size)):
		draw_line(Vector2(x, 0), Vector2(x, h), Color(1, 1, 1, 0.1))
	for y in range(0, h + 1, int(grid_size)):
		draw_line(Vector2(0, y), Vector2(w, y), Color(1, 1, 1, 0.1))
		
	var hs = grid_size / 2.0
	
	for b in map_data["bases"]: 
		draw_rect(Rect2(b.x - grid_size, b.y - grid_size, grid_size * 2, grid_size * 2), Color.CYAN)
		
	# Vẽ Hero
	if map_data.has("hero"):
		for hero in map_data["hero"]:
			draw_rect(Rect2(hero.x - hs, hero.y - hs, grid_size, grid_size), Color.BLUE)
			
	for s in map_data["spawns"]: draw_rect(Rect2(s.x - hs, s.y - hs, grid_size, grid_size), Color.MAGENTA)
	for o in map_data["obstacles"]: draw_rect(Rect2(o.x - hs, o.y - hs, grid_size, grid_size), Color.GRAY)
	for r in map_data["resources"]:
		var c = Color.YELLOW if r.type == "gold" else Color.DARK_GREEN
		draw_rect(Rect2(r.x - hs, r.y - hs, grid_size, grid_size), c)
	
	print("🖌️ [MAP EDITOR DEBUG] Đang vẽ lưới bắt đầu từ (0,0) đến (", w, ",", h, ")")

# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE map_editor.gd
func _place_item(snap_pos: Vector2) -> void:
	var dict_pos = {"x": snap_pos.x, "y": snap_pos.y}
	
	if not map_data.has("hero"): map_data["hero"] = []
		
	match current_tool:
		"base": map_data["bases"].append(dict_pos)
		"spawn": map_data["spawns"].append(dict_pos)
		"obstacle": map_data["obstacles"].append(dict_pos)
		"hero":
			# TÍNH NĂNG MỚI: Bắt buộc phải XÓA Hero cũ (nếu có) trước khi đặt mới
			if map_data["hero"].size() > 0:
				print("⚠️ [MAP EDITOR] Đã có Hero trên map! Hãy Chuột Phải xóa điểm cũ trước.")
				return 
			map_data["hero"].append(dict_pos)
			print("🦸 [MAP EDITOR] Đã chốt điểm sinh Hero tại: ", snap_pos)
		"gold", "wood": map_data["resources"].append({"type": current_tool, "x": snap_pos.x, "y": snap_pos.y})
		
	print("✅ [EDITOR] Đặt [", current_tool, "] tại ", snap_pos)

# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE map_editor.gd
func _remove_item_at(snap_pos: Vector2) -> void:
	var dict_pos = {"x": snap_pos.x, "y": snap_pos.y}
	map_data["spawns"].erase(dict_pos)
	map_data["obstacles"].erase(dict_pos)
	
	# Cho phép xóa Hero
	if map_data.has("hero"): map_data["hero"].erase(dict_pos)
	
	for i in range(map_data["bases"].size() - 1, -1, -1):
		var b = map_data["bases"][i]
		if abs(b.x - snap_pos.x) < grid_size and abs(b.y - snap_pos.y) < grid_size:
			map_data["bases"].remove_at(i)
			
	for i in range(map_data["resources"].size() - 1, -1, -1):
		var r = map_data["resources"][i]
		if r["x"] == snap_pos.x and r["y"] == snap_pos.y:
			map_data["resources"].remove_at(i)
