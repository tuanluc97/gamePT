extends CharacterBody2D

@export var speed: float = 250.0

func _physics_process(_delta: float) -> void:
	# Nhận tín hiệu di chuyển từ phím mũi tên hoặc WASD
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_dir * speed
	move_and_slide()
