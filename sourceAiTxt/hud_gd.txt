# THAY THẾ FILE hud.gd
extends CanvasLayer

@onready var gold_label: Label = $GoldLabel
@onready var wood_label: Label = $WoodLabel

var pos_label: Label = null
var hero_node: Node2D = null

# CHỈ SỬA ĐÚNG HÀM NÀY TRONG FILE hud.gd
func _ready() -> void:
	await get_tree().physics_frame
	_create_pos_label()
	
	# Kết nối tín hiệu đồng bộ Vàng và Gỗ từ Nhà chính lên UI
	var bases = get_tree().get_nodes_in_group("main_base")
	if bases.size() > 0:
		var base = bases[0]
		if not base.gold_changed.is_connected(_on_gold_changed):
			base.gold_changed.connect(_on_gold_changed)
		if not base.wood_changed.is_connected(_on_wood_changed):
			base.wood_changed.connect(_on_wood_changed)
		print("✅ [HUD] Đã kết nối đồng bộ Vàng và Gỗ với Nhà chính thành công!")

func _create_pos_label() -> void:
	pos_label = Label.new()
	pos_label.position = Vector2(20, 100) # Đặt phía dưới chữ Gỗ
	pos_label.add_theme_font_size_override("font_size", 20)
	add_child(pos_label)

func _process(_delta: float) -> void:
	if hero_node == null or not is_instance_valid(hero_node):
		hero_node = get_parent().get_node_or_null("Hero")
		
	if hero_node and pos_label:
		pos_label.text = "Tọa độ Hero: " + str(hero_node.global_position.round())

func _on_gold_changed(new_amount: int) -> void:
	gold_label.text = "Vàng: " + str(new_amount)

func _on_wood_changed(new_amount: int) -> void:
	wood_label.text = "Gỗ: " + str(new_amount)
