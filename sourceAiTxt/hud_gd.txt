extends CanvasLayer

@onready var gold_label: Label = $GoldLabel
@onready var wood_label: Label = $WoodLabel

func _ready() -> void:
	await get_tree().physics_frame
	
	var bases = get_tree().get_nodes_in_group("main_base")
	if bases.size() > 0:
		var main_base = bases[0]
		
		main_base.gold_changed.connect(_on_gold_changed)
		main_base.wood_changed.connect(_on_wood_changed)
		
		_on_gold_changed(main_base.gold_storage)
		_on_wood_changed(main_base.wood_storage)

func _on_gold_changed(new_amount: int) -> void:
	gold_label.text = "Vàng: " + str(new_amount)

func _on_wood_changed(new_amount: int) -> void:
	wood_label.text = "Gỗ: " + str(new_amount)
