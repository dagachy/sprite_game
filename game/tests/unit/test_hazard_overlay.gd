extends TestCase
## HazardOverlay.hazard_rects 순수 함수: 어느 셀을 강조하는가.

var _hz: Dictionary = {}  # Vector2i(col,row_world) -> bits

func _bits(x: float, sy: float) -> int:
	# scroll=0 기준 테스트용 조회. 셀 좌표로 변환.
	var c: int = floori((x - WorldStrip.BORDER) / WorldStrip.TILE)
	var r: int = floori(sy / WorldStrip.TILE)
	return int(_hz.get(Vector2i(c, r), 0))

func test_only_hazard_bit_cells_selected() -> void:
	_hz = {Vector2i(2, 3): ChunkDef.BIT_HAZARD, Vector2i(4, 3): ChunkDef.BIT_WALL, Vector2i(5, 5): ChunkDef.BIT_HAZARD | ChunkDef.BIT_COVER}
	var rs := HazardOverlay.hazard_rects(_bits, 0.0, 0.0, 200.0)
	check_eq(rs.size(), 2, "hazard 2 cells (wall excluded)")
	check(rs.has(Rect2(12.0 + 2 * 16.0, 48.0, 16.0, 16.0)), "cell (2,3) rect")
	check(rs.has(Rect2(12.0 + 5 * 16.0, 80.0, 16.0, 16.0)), "mixed hazard|cover included")

func test_empty_when_no_hazard() -> void:
	_hz = {}
	check_eq(HazardOverlay.hazard_rects(_bits, 0.0).size(), 0, "none")

func test_scroll_shifts_rect_y_aligned_to_world_rows() -> void:
	_hz = {}
	var sc := 5.0
	var f := func(x: float, sy: float) -> int:
		var r: int = floori((sy - sc) / WorldStrip.TILE)
		return ChunkDef.BIT_HAZARD if r == 2 and floori((x - WorldStrip.BORDER) / WorldStrip.TILE) == 0 else 0
	var rs := HazardOverlay.hazard_rects(f, sc, 0.0, 200.0)
	check_eq(rs.size(), 1, "one cell")
	if rs.size() == 1:
		check_eq(rs[0].position.y, 2 * 16.0 + sc, "y = row*16 + scroll")
		check_eq(rs[0].position.x, 12.0, "x at first column")

func test_range_limits_rows() -> void:
	_hz = {Vector2i(0, 100): ChunkDef.BIT_HAZARD}
	check_eq(HazardOverlay.hazard_rects(_bits, 0.0, -16.0, 400.0).size(), 0, "out of range row skipped")
