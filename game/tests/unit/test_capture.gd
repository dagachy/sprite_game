extends TestCase
## CaptureRig (C5): 200장 상한, 가장 오래된 생성물부터 삭제, 생성물(cap_ 접두사)만 건드린다.

const TDIR := "user://test_captures"

func _clean() -> void:
	DirAccess.make_dir_recursive_absolute(TDIR)
	var da := DirAccess.open(TDIR)
	for f in da.get_files():
		da.remove(f)

func test_prune_keeps_newest_200_and_spares_others() -> void:
	_clean()
	var da := DirAccess.open(TDIR)
	for i in 205:
		var fa := FileAccess.open(TDIR.path_join("cap_%013d_0000.png" % (1000 + i)), FileAccess.WRITE)
		fa.store_string("x")
		fa.close()
	var keep := FileAccess.open(TDIR.path_join("notes.txt"), FileAccess.WRITE)
	keep.store_string("not a capture")
	keep.close()
	var removed: int = CaptureRig.prune(TDIR, 200)
	check_eq(removed, 5, "5 oldest removed")
	check(not da.file_exists("cap_%013d_0000.png" % 1000), "oldest removed")
	check(not da.file_exists("cap_%013d_0000.png" % 1004), "fifth oldest removed")
	check(da.file_exists("cap_%013d_0000.png" % 1005), "sixth oldest kept")
	check(da.file_exists("notes.txt"), "non-capture file untouched")
	var count := 0
	for f in da.get_files():
		if f.begins_with("cap_"):
			count += 1
	check_eq(count, 200, "200 captures remain")
	_clean()

func test_file_name_format() -> void:
	var n: String = CaptureRig.file_name(7)
	check(n.begins_with("cap_"), "prefix")
	check(n.ends_with("_0007.png"), "sequence suffix")
	check_eq(n.length(), 4 + 13 + 1 + 4 + 4, "fixed-width name length")
