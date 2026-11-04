extends Node
## JSON Lines 로거. user://logs/runs.jsonl (판당 1줄), user://logs/events.jsonl (이벤트).
## 테스트에서는 Log.enabled = false 로 끈다.

var enabled: bool = true
var dir_path: String = "user://logs"

func _ensure_dir() -> void:
	DirAccess.make_dir_recursive_absolute(dir_path)

func _append(file: String, rec: Dictionary) -> void:
	if not enabled:
		return
	_ensure_dir()
	var path := dir_path.path_join(file)
	var f: FileAccess
	if FileAccess.file_exists(path):
		f = FileAccess.open(path, FileAccess.READ_WRITE)
		if f != null:
			f.seek_end()
	else:
		f = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.store_line(JSON.stringify(rec))
	f.close()

func run_record(rec: Dictionary) -> void:
	_append("runs.jsonl", rec)

func event(ev_name: String, data: Dictionary = {}) -> void:
	var rec := data.duplicate()
	rec["ev"] = ev_name
	rec["ts"] = Time.get_unix_time_from_system()
	_append("events.jsonl", rec)
