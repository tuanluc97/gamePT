extends Control

func _ready() -> void:
	print("🎮 [MENU] Đang khởi động Menu Game...")

# Gọi hàm này khi bấm nút Start
func _on_start_pressed() -> void:
	print("🚀 [MENU] BẮT ĐẦU GAME! Đang tải dữ liệu từ Global...")
	print(" -> Máu nhà chính: ", Global.base_hp)
	print(" -> Thời gian sinh quái: ", Global.wave_interval, "s")
	get_tree().change_scene_to_file("res://scenes/main.tscn")

# Gọi các hàm này khi kéo thanh trượt (HSlider) trong phần Cài đặt
func _on_hp_slider_value_changed(value: float) -> void:
	Global.base_hp = value
func _on_wave_slider_value_changed(value: float) -> void:
	Global.wave_interval = value
func _on_speed_slider_value_changed(value: float) -> void:
	Global.worker_speed = value
func _on_carry_cap_slider_value_changed(value: float) -> void:
	Global.worker_carry_cap = int(value)
func _on_harvest_amt_slider_value_changed(value: float) -> void:
	Global.worker_harvest_amt = int(value)
