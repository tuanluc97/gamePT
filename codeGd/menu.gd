extends Control
@onready var start_btn: Button = $MainMenuVBox/StartBtn
@onready var open_settings_btn: Button = $MainMenuVBox/OpenSettingsBtn
@onready var main_menu_vbox: VBoxContainer = $MainMenuVBox # THÊM BIẾN NÀY ĐỂ TẮT BẬT
@onready var settings_panel: PanelContainer = $SettingsPanel

# ĐÃ SỬA ĐƯỜNG DẪN: Chèn thêm MarginContainer vào giữa
@onready var close_settings_btn: Button = $SettingsPanel/MarginContainer/SettingsVBox/CloseSettingsBtn

@onready var hp_slider: HSlider = $SettingsPanel/MarginContainer/SettingsVBox/HPRow/HPSlider
@onready var wave_slider: HSlider = $SettingsPanel/MarginContainer/SettingsVBox/WaveRow/WaveSlider
@onready var speed_slider: HSlider = $SettingsPanel/MarginContainer/SettingsVBox/SpeedRow/SpeedSlider
@onready var carry_slider: HSlider = $SettingsPanel/MarginContainer/SettingsVBox/CarryRow/CarrySlider
@onready var harvest_slider: HSlider = $SettingsPanel/MarginContainer/SettingsVBox/HarvestRow/HarvestSlider

@onready var hp_val_label: Label = $SettingsPanel/MarginContainer/SettingsVBox/HPRow/HPValue
@onready var wave_val_label: Label = $SettingsPanel/MarginContainer/SettingsVBox/WaveRow/WaveValue
@onready var speed_val_label: Label = $SettingsPanel/MarginContainer/SettingsVBox/SpeedRow/SpeedValue
@onready var carry_val_label: Label = $SettingsPanel/MarginContainer/SettingsVBox/CarryRow/CarryValue
@onready var harvest_val_label: Label = $SettingsPanel/MarginContainer/SettingsVBox/HarvestRow/HarvestValue
var map_select_panel: PanelContainer
# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE menu.gd
func _ready() -> void:
	print("🎮 [MENU] Khởi tạo giao diện Menu thành công!")
	
	# Kết nối sự kiện nút bấm Bắt đầu
	start_btn.pressed.connect(_on_start_pressed)
	
	# BẢN VÁ LỖI ĐÈ GIAO DIỆN: Ẩn Menu chính khi mở Tùy chỉnh
	open_settings_btn.pressed.connect(func(): 
		settings_panel.visible = true
		main_menu_vbox.visible = false
		print("⚙️ [MENU] Mở bảng Tùy chỉnh, đã ẩn Menu chính.")
	)
	close_settings_btn.pressed.connect(func(): 
		settings_panel.visible = false
		main_menu_vbox.visible = true
		print("⚙️ [MENU] Đóng bảng Tùy chỉnh, quay lại Menu chính.")
	)
	
	# Trạng thái ban đầu khi vừa mở game
	settings_panel.visible = false
	main_menu_vbox.visible = true
	
	# Đồng bộ giá trị từ Global lên giao diện HSlider
	_sync_ui_from_global()
	_setup_map_editor_ui()
	# Kết nối tín hiệu khi kéo thanh trượt
	hp_slider.value_changed.connect(_on_hp_changed)
	wave_slider.value_changed.connect(_on_wave_changed)
	speed_slider.value_changed.connect(_on_speed_changed)
	carry_slider.value_changed.connect(_on_carry_changed)
	harvest_slider.value_changed.connect(_on_harvest_changed)
	
func _sync_ui_from_global() -> void:
	if typeof(Global) != TYPE_NIL:
		hp_slider.value = Global.base_hp
		wave_slider.value = Global.wave_interval
		speed_slider.value = Global.worker_speed
		carry_slider.value = Global.worker_carry_cap
		harvest_slider.value = Global.worker_harvest_amt
		
		_update_labels()

func _update_labels() -> void:
	hp_val_label.text = str(hp_slider.value)
	wave_val_label.text = str(wave_slider.value) + "s"
	speed_val_label.text = str(speed_slider.value)
	carry_val_label.text = str(carry_slider.value)
	harvest_val_label.text = str(harvest_slider.value)

func _on_hp_changed(val: float) -> void:
	Global.base_hp = val
	hp_val_label.text = str(val)
	print("⚙️ [CÀI ĐẶT] Máu nhà chính gán thành: ", val)

func _on_wave_changed(val: float) -> void:
	Global.wave_interval = val
	wave_val_label.text = str(val) + "s"
	print("⚙️ [CÀI ĐẶT] Thời gian Wave gán thành: ", val, "s")

func _on_speed_changed(val: float) -> void:
	Global.worker_speed = val
	speed_val_label.text = str(val)
	print("⚙️ [CÀI ĐẶT] Tốc độ Nông dân gán thành: ", val)

func _on_carry_changed(val: float) -> void:
	Global.worker_carry_cap = int(val)
	carry_val_label.text = str(val)
	print("⚙️ [CÀI ĐẶT] Sức chứa gán thành: ", val)

func _on_harvest_changed(val: float) -> void:
	Global.worker_harvest_amt = int(val)
	harvest_val_label.text = str(val)
	print("⚙️ [CÀI ĐẶT] Lượng thu hoạch gán thành: ", val)

func _on_start_pressed() -> void:
	print("▶️ [MENU] Mở giao diện chọn Map...")
	main_menu_vbox.hide() # Ẩn menu chính
	_show_map_selection_ui()
	
func _setup_map_editor_ui() -> void:
	var map_hbox = HBoxContainer.new()
	main_menu_vbox.add_child(map_hbox) # Thêm vào Menu chính
	
	var btn_create = Button.new()
	btn_create.text = "➕ Tạo Map Mới"
	btn_create.pressed.connect(func():
		Global.map_to_edit = ""
		get_tree().change_scene_to_file("res://scenes/map_editor.tscn")
	)
	map_hbox.add_child(btn_create)
	
	var map_list = MapDataHandler.get_saved_maps()
	if map_list.size() > 0:
		var opt_maps = OptionButton.new()
		for m in map_list:
			opt_maps.add_item(m)
		map_hbox.add_child(opt_maps)
		
		var btn_load = Button.new()
		btn_load.text = "✏️ Sửa Map"
		btn_load.pressed.connect(func():
			Global.map_to_edit = opt_maps.get_item_text(opt_maps.selected)
			get_tree().change_scene_to_file("res://scenes/map_editor.tscn")
		)
		map_hbox.add_child(btn_load)
		print("🗺️ [MENU] Đã load danh sách map vào Dropdown.")
func _show_map_selection_ui() -> void:
	if map_select_panel:
		map_select_panel.show()
		return
		
	map_select_panel = PanelContainer.new()
	map_select_panel.set_anchors_preset(Control.PRESET_CENTER)
	add_child(map_select_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	map_select_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "🗺️ CHỌN BẢN ĐỒ ĐỂ CHƠI"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var map_list = MapDataHandler.get_saved_maps()
	if map_list.is_empty():
		var err = Label.new()
		err.text = "Chưa có map nào! Hãy vào Map Editor để tạo."
		err.modulate = Color.RED
		vbox.add_child(err)
	else:
		var opt_maps = OptionButton.new()
		for m in map_list:
			opt_maps.add_item(m)
		vbox.add_child(opt_maps)
		
		var play_btn = Button.new()
		play_btn.text = "⚔️ BẮT ĐẦU VÀO GAME"
		play_btn.modulate = Color.GREEN
		play_btn.pressed.connect(func():
			Global.current_map_to_play = opt_maps.get_item_text(opt_maps.selected)
			print("🚀 [MENU] Tiến hành load Map: ", Global.current_map_to_play)
			get_tree().change_scene_to_file("res://scenes/main.tscn")
		)
		vbox.add_child(play_btn)
		
	var back_btn = Button.new()
	back_btn.text = "🔙 Quay lại"
	back_btn.pressed.connect(func():
		map_select_panel.hide()
		main_menu_vbox.show()
	)
	vbox.add_child(back_btn)
