class_name ChunkDb extends RefCounted
## data/chunks/*.txt 를 읽어 {id: ChunkDef} 로 만든다.
## 주의: .txt 는 리소스가 아니라서 내보내기(export) 때 "*.txt" include 필터를 추가해야 한다.

const DIR := "res://data/chunks"

static func load_all(dir: String = DIR) -> Dictionary:
	var out: Dictionary = {}
	var da := DirAccess.open(dir)
	if da == null:
		push_error("ChunkDb: cannot open %s" % dir)
		return out
	for f in da.get_files():
		if not f.ends_with(".txt"):
			continue
		var fa := FileAccess.open(dir.path_join(f), FileAccess.READ)
		if fa == null:
			continue
		var c := ChunkDef.parse(fa.get_as_text())
		if c.id != &"":
			out[c.id] = c
	return out
