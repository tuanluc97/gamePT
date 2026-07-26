extends Node2D

# Khai báo các biến cơ bản cho Game Phòng thủ
var player_gold: int = 100
var castle_health: int = 20

func _ready() -> void:
	print("--- GAME PHÒNG THỦ BẮT ĐẦU ---")
	print("Vàng hiện có: ", player_gold)
	print("Máu thành: ", castle_health)

func _process(delta: float) -> void:
	# Vùng xử lý logic đếm thời gian hoặc cập nhật khung hình
	pass
