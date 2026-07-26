extends StaticBody2D

var gold_storage: int = 0 
var wood_storage: int = 0 

# Tải sẵn file nông dân để sinh ra (spawn)
@export var worker_scene: PackedScene

func _unhandled_input(event: InputEvent) -> void:
	# Bấm phím SPACE (hoặc phím Enter) để xin nông dân
	if event.is_action_pressed("ui_accept"):
		spawn_worker()

func spawn_worker() -> void:
	if worker_scene:
		var worker = worker_scene.instantiate()
		worker.global_position = $SpawnPoint.global_position
		get_parent().add_child(worker)
		print("Đã xin 1 Nông dân!")

func add_resource(type: String, amount: int) -> void:
	if type == "gold":
		gold_storage += amount
		print("Nhà chính nhận ", amount, " Vàng! Tổng Vàng: ", gold_storage)
