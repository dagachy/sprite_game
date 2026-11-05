extends Node
## JSON Lines 로거 (P3 정본). user://logs/runs.jsonl (판당 1줄), user://logs/events.jsonl (이벤트).
## 봉투: schema_ver, seq, t_ms, ts, ev, run_id + 파라미터(평면). 파일이 5MB를 넘으면 회전(백업 3개).
## 릴리스 빌드에서는 기본 OFF(OS.is_debug_build()). 테스트에서는 Log.enabled = false 로 끈다.

const SCHEMA_VER := 1
const ROTATE_BYTES := 5 * 1024 * 1024
const ROTATE_KEEP := 3
const RUNS_FILE := "runs.jsonl"
const EVENTS_FILE := "events.jsonl"

var enabled: bool = OS.is_debug_build()
var dir_path: String = "user://logs"
var run_id: String = ""   # 현재 판 ID. main.gd 가 판 시작 시 설정한다
var _seq: int = -1        # 마지막으로 쓴 seq. -1 이면 아직 파일에서 읽지 않았다

func _ensure_dir() -> void:
	DirAccess.make_dir_recursive_absolute(dir_path)

## 파일이 ROTATE_BYTES 이상이면 name.1.ext ... name.KEEP.ext 로 민다. 가장 오래된 백업은 버린다.
func _rotate_if_needed(file: String) -> void:
	var path := dir_path.path_join(file)
	if not FileAccess.file_exists(path):
		return
	var fa := FileAccess.open(path, FileAccess.READ)
	if fa == null:
		return
	var size := fa.get_length()
	fa.close()
	if size < ROTATE_BYTES:
		return
	var base := file.get_basename()
	var ext := file.get_extension()
	DirAccess.remove_absolute(dir_path.path_join("%s.%d.%s" % [base, ROTATE_KEEP, ext]))
	for i in range(ROTATE_KEEP - 1, 0, -1):
		var from := dir_path.path_join("%s.%d.%s" % [base, i, ext])
		if FileAccess.file_exists(from):
			DirAccess.rename_absolute(from, dir_path.path_join("%s.%d.%s" % [base, i + 1, ext]))
	DirAccess.rename_absolute(path, dir_path.path_join("%s.1.%s" % [base, ext]))

## events 파일의 마지막 seq 를 읽는다(현재 파일, 없으면 백업 1번). 없으면 -1.
func _load_seq() -> void:
	_seq = -1
	for name in [EVENTS_FILE, "events.1.jsonl"]:
		var path := dir_path.path_join(name)
		if not FileAccess.file_exists(path):
			continue
		var fa := FileAccess.open(path, FileAccess.READ)
		if fa == null:
			continue
		var lines := fa.get_as_text().split("\n", false)
		fa.close()
		for i in range(lines.size() - 1, -1, -1):
			var js := JSON.new()
			if js.parse(lines[i]) == OK and js.data is Dictionary and (js.data as Dictionary).has("seq"):
				_seq = int((js.data as Dictionary)["seq"])
				return

func _next_seq() -> int:
	if _seq < 0:
		_load_seq()
	_seq += 1
	return _seq

func _append(file: String, rec: Dictionary) -> void:
	if not enabled:
		return
	_ensure_dir()
	_rotate_if_needed(file)
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
	if not enabled:
		return
	var out := rec.duplicate()
	out["schema_ver"] = SCHEMA_VER
	_append(RUNS_FILE, out)

func event(ev_name: String, data: Dictionary = {}) -> void:
	if not enabled:
		return
	var rec := data.duplicate()
	rec["schema_ver"] = SCHEMA_VER
	rec["seq"] = _next_seq()
	rec["t_ms"] = Time.get_ticks_msec()
	rec["ts"] = Time.get_unix_time_from_system()
	rec["ev"] = ev_name
	rec["run_id"] = run_id
	_append(EVENTS_FILE, rec)
