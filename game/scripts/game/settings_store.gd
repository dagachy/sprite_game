class_name SettingsStore extends RefCounted
## user://settings.cfg 저장소. 메타 세이브와 분리. 모든 I/O 는 실패해도 예외 없이 기본값으로 진행한다.

const DEFAULT_PATH: String = "user://settings.cfg"
const SECTION: String = "game"

var path: String
var data: Dictionary = {"first_run_done": false}
var last_error: int = OK

func _init(p: String = DEFAULT_PATH) -> void:
	path = p

func load_file() -> bool:
	var cf := ConfigFile.new()
	var err: int = cf.load(path)
	last_error = err
	if err != OK:
		return false   # 파일 없음/손상: 기본값 유지
	for k in cf.get_section_keys(SECTION) if cf.has_section(SECTION) else PackedStringArray():
		data[k] = cf.get_value(SECTION, k)
	return true

func save_file() -> bool:
	var cf := ConfigFile.new()
	for k in data:
		cf.set_value(SECTION, String(k), data[k])
	var err: int = cf.save(path)
	last_error = err
	return err == OK

func get_bool(key: String, default_value: bool = false) -> bool:
	var v: Variant = data.get(key, default_value)
	return v if v is bool else default_value

func set_value(key: String, value: Variant) -> bool:
	data[key] = value
	return save_file()

func first_run_done() -> bool:
	return get_bool("first_run_done", false)
