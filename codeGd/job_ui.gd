extends CanvasLayer

@onready var idle_label: Label = $JobPanel/VBox/IdleRow/IdleLabel
@onready var gold_label: Label = $JobPanel/VBox/GoldRow/GoldLabel
@onready var wood_label: Label = $JobPanel/VBox/WoodRow/WoodLabel
@onready var build_label: Label = $JobPanel/VBox/BuildRow/BuildLabel
@onready var scout_label: Label = $JobPanel/VBox/ScoutRow/ScoutLabel 

@onready var plus_gold_btn: Button = $JobPanel/VBox/GoldRow/PlusGoldBtn
@onready var minus_gold_btn: Button = $JobPanel/VBox/GoldRow/MinusGoldBtn

@onready var plus_wood_btn: Button = $JobPanel/VBox/WoodRow/PlusWoodBtn
@onready var minus_wood_btn: Button = $JobPanel/VBox/WoodRow/MinusWoodBtn

@onready var plus_build_btn: Button = $JobPanel/VBox/BuildRow/PlusBuildBtn
@onready var minus_build_btn: Button = $JobPanel/VBox/BuildRow/MinusBuildBtn

@onready var plus_scout_btn: Button = $JobPanel/VBox/ScoutRow/PlusScoutBtn
@onready var minus_scout_btn: Button = $JobPanel/VBox/ScoutRow/MinusScoutBtn

func _ready() -> void:
	plus_gold_btn.pressed.connect(func(): _assign_job(1, 1))
	minus_gold_btn.pressed.connect(func(): _unassign_job(1))

	plus_wood_btn.pressed.connect(func(): _assign_job(2, 2))
	minus_wood_btn.pressed.connect(func(): _unassign_job(2))

	plus_build_btn.pressed.connect(func(): _assign_job(3, 3))
	minus_build_btn.pressed.connect(func(): _unassign_job(3))
	
	plus_scout_btn.pressed.connect(func(): _assign_job(4, 4))
	minus_scout_btn.pressed.connect(func(): _unassign_job(4))

func _process(_delta: float) -> void:
	_update_ui_counts()

func _assign_job(_target_job_enum: int, job_type: int) -> void:
	var workers = get_tree().get_nodes_in_group("workers")
	
	# 1. Tìm kiến đang rảnh rỗi trước
	for worker in workers:
		if worker.current_job == 0:
			worker.set_job(job_type)
			return
			
	# 2. Nếu ko có kiến rảnh, Ưu tiên bắt kiến Trinh sát (4) đi làm việc!
	if job_type != 4:
		for worker in workers:
			if worker.current_job == 4:
				worker.set_job(job_type)
				return

func _unassign_job(from_job_type: int) -> void:
	var workers = get_tree().get_nodes_in_group("workers")
	for worker in workers:
		if worker.current_job == from_job_type:
			worker.set_job(0) # Trả về rảnh rỗi
			break

func _update_ui_counts() -> void:
	var workers = get_tree().get_nodes_in_group("workers")
	var idle_count: int = 0
	var gold_count: int = 0
	var wood_count: int = 0
	var build_count: int = 0
	var scout_count: int = 0 

	for worker in workers:
		match worker.current_job:
			0: idle_count += 1
			1: gold_count += 1
			2: wood_count += 1
			3: build_count += 1
			4: scout_count += 1

	idle_label.text = "Rảnh rỗi: " + str(idle_count)
	gold_label.text = "Đào vàng: " + str(gold_count)
	wood_label.text = "Chặt gỗ: " + str(wood_count)
	build_label.text = "Xây dựng: " + str(build_count)
	scout_label.text = "Trinh sát: " + str(scout_count)
