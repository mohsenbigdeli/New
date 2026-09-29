extends RefCounted
class_name FarmSave
const PATH = "user://greenfield_pro.json"
static func number(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value))
static func valid(data: Variant) -> bool:
	if not data is Dictionary or data.get("version") != 1:
		return false
	if not data.get("plots") is Array or data.plots.size() != 8:
		return false
	if not data.get("position") is Array or data.position.size() != 2:
		return false
	for coordinate in data.position:
		if not number(coordinate): return false
	for key in ["day", "minute", "harvest"]:
		if not number(data.get(key)): return false
	for item in data.plots:
		if not item is Dictionary or not number(item.get("state")) or not number(item.get("grow_time")):
			return false
		if int(item.state) < 0 or int(item.state) > 4:
			return false
	return true
static func read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	var data: Variant = json.data
	return data if valid(data) else {}
static func load_snapshot(path: String = PATH) -> Dictionary:
	var data := read_file(path)
	return data if not data.is_empty() else read_file(path + ".bak")
static func write_snapshot(data: Dictionary, path: String = PATH) -> bool:
	if not valid(data):
		return false
	var temp := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if not temp:
		return false
	temp.store_string(JSON.stringify(data))
	temp.flush()
	var error := temp.get_error()
	temp.close()
	if error != OK or read_file(path + ".tmp").is_empty():
		return false
	if not read_file(path).is_empty():
		if DirAccess.copy_absolute(path, path + ".bak") != OK:
			return false
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	if DirAccess.rename_absolute(path + ".tmp", path) != OK:
		if FileAccess.file_exists(path + ".bak"):
			DirAccess.copy_absolute(path + ".bak", path)
		return false
	return true
