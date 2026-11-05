extends TestCase
## T-06 (린터 L1~L5 범위), 로더, 스테이지 구성, T-08 스크롤

func test_t06_chunks_lint_clean() -> void:
	var db: Dictionary = ChunkDb.load_all()
	check_eq(db.size(), 11, "청크 파일 수(10 + 광장 + 아레나 - 1 = 11)")
	for id in db.keys():
		var errs: Array[String] = ChunkLint.lint(db[id])
		for e in errs:
			check(false, e)
	check(true, "lint")

func test_t06_lint_l0_header_clean_and_defects() -> void:
	var da := DirAccess.open(ChunkDb.DIR)
	for f in da.get_files():
		if not f.ends_with(".txt"):
			continue
		var fa := FileAccess.open(ChunkDb.DIR.path_join(f), FileAccess.READ)
		for e in ChunkLint.lint_header(f.get_basename(), fa.get_as_text()):
			check(false, e)
	check(ChunkLint.lint_header("x", "id: x\nrole: OPEN\nwidth: 12\n---\n").is_empty(), "L0 ok header")
	check(ChunkLint.lint_header("x", "id: x\nrole: OPNE\nwidth: 12\n---\n").size() > 0, "L0 role typo")
	check(ChunkLint.lint_header("x", "id: y\nrole: OPEN\nwidth: 12\n---\n").size() > 0, "L0 id != filename")
	check(ChunkLint.lint_header("x", "id: x\nrole: OPEN\nwidth: 11\n---\n").size() > 0, "L0 width")
	check(ChunkLint.lint_header("x", "id: x\nroel: OPEN\nwidth: 12\n---\n").size() > 0, "L0 unknown key")

func test_t06_lint_l4b_plaza_seam() -> void:
	var rows := PackedStringArray()
	for i in 12:
		rows.append(".".repeat(12))
	var c := ChunkDef.new()
	c.id = &"plaza_t"
	c.role = ChunkDef.Role.PLAZA
	c.width = 12
	c.height = 12
	c.grid = rows
	check(ChunkLint.lint(c).is_empty(), "L4b clean plaza")
	var g: PackedStringArray = rows.duplicate()
	g[1] = "#..........."
	c.grid = g
	check(ChunkLint.lint(c).size() > 0, "L4b plaza seam")

func test_t06_lint_catches_defects() -> void:
	var base: PackedStringArray = PackedStringArray()
	for i in 24:
		base.append(".".repeat(12))
	var c := ChunkDef.new()
	c.id = &"bad"
	c.role = ChunkDef.Role.OPEN
	c.width = 12
	c.height = 24
	# L1: 행 수 부족
	c.grid = base.slice(0, 23)
	check(ChunkLint.lint(c).size() > 0, "L1 rows")
	# L2: 허용 안 되는 문자
	var g2: PackedStringArray = base.duplicate()
	g2[5] = "..x........."
	c.grid = g2
	check(ChunkLint.lint(c).size() > 0, "L2 char")
	# L3: 통로 2칸
	var g3: PackedStringArray = base.duplicate()
	g3[5] = "##.##.##.##."
	c.grid = g3
	check(ChunkLint.lint(c).size() > 0, "L3 passage")
	# L4: 이음매 행 장애물
	var g4: PackedStringArray = base.duplicate()
	g4[0] = "....#......."
	c.grid = g4
	check(ChunkLint.lint(c).size() > 0, "L4 seam")
	# L5: 하단 장애물 > 18
	var g5: PackedStringArray = base.duplicate()
	for r in range(18, 22):
		g5[r] = "####....####"
	c.grid = g5
	check(ChunkLint.lint(c).size() > 0, "L5 bottom density")

func test_loader_counts_match_text() -> void:
	var db: Dictionary = ChunkDb.load_all()
	for id in db.keys():
		var d: ChunkDef = db[id]
		var raw: String = FileAccess.get_file_as_string("res://data/chunks/%s.txt" % String(id))
		var body: String = raw.split("---", true, 1)[1]
		check_eq(d.count_char("c"), body.count("c"), "%s c count" % String(id))
		check_eq(d.count_char("#"), body.count("#"), "%s # count" % String(id))

func test_recipe_rules() -> void:
	for sd in range(1, 200):
		var ids: Array[StringName] = StageRecipe.pick_slots(sd)
		check_eq(ids.size(), 6, "6 slots")
		check_eq(ids[0], &"open_01", "slot0")
		check_eq(ids[3], &"cover_01", "slot3 cover_01")
		check_eq(ids[4], &"choke_01", "slot4 choke_01")
		var seen: Dictionary = {}
		for i in ids.size():
			check(not seen.has(ids[i]), "no repeat seed %d: %s" % [sd, str(ids)])
			seen[ids[i]] = true
			if i > 0 and String(ids[i]).begins_with("hazard") and String(ids[i - 1]).begins_with("hazard"):
				check(false, "consecutive hazard seed %d" % sd)
	var early: Array[StringName] = StageRecipe.pick_slots(5, true)
	check_eq(early[1], &"open_02", "판1~3 슬롯1")
	check_eq(early[2], &"hazard_01", "판1~3 슬롯2")

func test_cover_slot_has_cover_and_markers() -> void:
	var db: Dictionary = ChunkDb.load_all()
	var c: ChunkDef = db[&"cover_01"]
	check(c.count_char("c") >= 3, "cover_01 엄폐 3+")
	check(c.count_char("S") >= 2, "cover_01 S 2+")

func test_t08_scroll_model_timeline() -> void:
	var bal := Balance.new()
	var m := ScrollModel.new(bal)
	var off: float = 0.0
	var dt: float = 1.0 / 60.0
	var t: float = 0.0
	var hold_start: float = -1.0
	var hold_end: float = -1.0
	var off_at_hold: float = 0.0
	var plaza_origin: float = -2112.0
	var steps: int = 0
	while t < 400.0 and m.state != ScrollModel.S.ENTRY:
		var plaza_top: float = plaza_origin + off
		var prev: int = m.state
		off += m.step(dt, 0, false, plaza_top, -9999.0, -9999.0, false)
		t += dt
		if m.state == ScrollModel.S.PLAZA_HOLD and prev != ScrollModel.S.PLAZA_HOLD:
			hold_start = t
			off_at_hold = off
		if prev == ScrollModel.S.PLAZA_HOLD and m.state != ScrollModel.S.PLAZA_HOLD:
			hold_end = t
		steps += 1
	check_near(hold_start, 144.0, 0.2, "광장 정지 시작 시각")
	check_near(off_at_hold, 2256.0, 1.0, "정지 시 스크롤 오프셋")
	check_near(hold_end - hold_start, bal.plaza_hold_time, 0.1, "광장 정지 시간")

func test_t08_crowd_slows_to_0_6() -> void:
	var bal := Balance.new()
	var m := ScrollModel.new(bal)
	for i in 120:
		m.step(1.0 / 60.0, 24, false, -9999.0, -9999.0, -9999.0, false)
	check_near(m.ratio, 1.0, 0.001, "alive 24 -> 1.0")
	for i in 120:
		m.step(1.0 / 60.0, 36, false, -9999.0, -9999.0, -9999.0, false)
	check_near(m.ratio, 0.6, 0.01, "alive 36 -> 0.6")
	for i in 240:
		m.step(1.0 / 60.0, 0, true, -9999.0, -9999.0, -9999.0, false)
	check_near(m.ratio, 0.6, 0.01, "정예 생존 -> 0.6")
	for i in 240:
		m.step(1.0 / 60.0, 0, false, -9999.0, -9999.0, -9999.0, false)
	check_near(m.ratio, 1.0, 0.01, "복귀 1.0")

func test_plaza_early_exit() -> void:
	var bal := Balance.new()
	var m := ScrollModel.new(bal)
	m.state = ScrollModel.S.PLAZA_HOLD
	m.step(1.0 / 60.0, 0, false, 0.0, 0.0, 0.0, false)
	check_eq(m.state, ScrollModel.S.PLAZA_HOLD, "hold")
	m.step(1.0 / 60.0, 0, false, 0.0, 0.0, 0.0, true)
	check_eq(m.state, ScrollModel.S.PLAZA_ACCEL, "출구 진입 시 조기 종료")
