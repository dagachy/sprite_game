extends SceneTree
## 청크 린터 CLI: godot --headless --path game --script res://tools/run_chunk_lint.gd
## 종료 코드 0 오류 없음 / 1 오류 있음 / 2 청크 폴더 오류.

func _init() -> void:
	var db: Dictionary = ChunkDb.load_all()
	if db.is_empty():
		printerr("no chunks")
		quit(2)
		return
	var bad: int = 0
	var da := DirAccess.open(ChunkDb.DIR)
	for f in da.get_files():
		if f.ends_with(".txt"):
			var fa := FileAccess.open(ChunkDb.DIR.path_join(f), FileAccess.READ)
			for e in ChunkLint.lint_header(f.get_basename(), fa.get_as_text()):
				print(e)
				bad += 1
	var ids: Array = db.keys()
	ids.sort()
	for id in ids:
		for e in ChunkLint.lint(db[id]):
			print(e)
			bad += 1
	print("chunks %d, errors %d" % [db.size(), bad])
	quit(1 if bad > 0 else 0)
