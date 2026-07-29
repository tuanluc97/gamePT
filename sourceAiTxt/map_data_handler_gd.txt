extends Node
class_name MapDataHandler

# Dùng user:// để đảm bảo có quyền tạo/ghi file khi Export ra file chạy .exe/.apk
const SAVE_DIR = "user://maps/" 

static func save_map(filename: String, map_data: Dictionary) -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)
		
	var path = SAVE_DIR + filename + ".json"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(map_data, "\t"))
		# BẰNG CHỨNG LOG: In ra đường dẫn tuyệt đối để bạn dễ dàng tìm mở file JSON
		print("💾 [MAP HANDLER] Thành công! Đã lưu map tại: ", ProjectSettings.globalize_path(path))
	else:
		print("🚨 [MAP HANDLER] LỖI: Không thể mở file để ghi: ", path)

static func load_map(filename: String) -> Dictionary:
	var path = SAVE_DIR + filename + ".json"
	if not FileAccess.file_exists(path):
		print("🚨 [MAP HANDLER] LỖI: Không tìm thấy file map: ", path)
		return {}
		
	var file = FileAccess.open(path, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	
	if error == OK:
		print("📂 [MAP HANDLER] Tải map thành công: ", filename)
		return json.data as Dictionary
	else:
		print("🚨 [MAP HANDLER] LỖI parse JSON tại dòng ", json.get_error_line(), ": ", json.get_error_message())
		return {}
# THÊM HÀM NÀY VÀO CUỐI FILE map_data_handler.gd
static func get_saved_maps() -> Array[String]:
	var maps: Array[String] = []
	if DirAccess.dir_exists_absolute(SAVE_DIR):
		var dir = DirAccess.open(SAVE_DIR)
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				maps.append(file_name.replace(".json", ""))
			file_name = dir.get_next()
	print("📂 [MAP HANDLER] Đã tìm thấy ", maps.size(), " maps đã lưu.")
	return maps
