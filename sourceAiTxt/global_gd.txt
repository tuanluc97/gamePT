extends Node
# THÊM DÒNG NÀY LÊN ĐẦU FILE global.gd (Ngay dưới dòng extends Node)
signal log_event(msg_type: String, message: String)
# CÁC THÔNG SỐ MẶC ĐỊNH
var base_hp: float = 200.0
var wave_interval: float = 180.0
var worker_speed: float = 120.0
var worker_carry_cap: int = 1
var worker_harvest_amt: int = 1
var map_to_edit: String = "" # Rỗng = Tạo mới, Có tên = Load map cũ
var current_map_to_play: String = ""
