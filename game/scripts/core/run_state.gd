extends Node
## 오토로드: 세션 간 메타(MetaState) 보관과 user://meta.json 저장. 로직은 MetaState 코어에 있다.

var meta: MetaState = MetaState.new()
var save_enabled: bool = true
const PATH := "user://meta.json"

func _ready() -> void:
	load_meta()

func load_meta() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		meta = MetaState.from_dict(parsed)

func save_meta() -> void:
	if not save_enabled:
		return
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(meta.to_dict()))

func is_early_run() -> bool:
	return meta.runs_played < 3
