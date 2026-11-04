class_name ChunkLint extends RefCounted
## 청크 린터 (level 린터 L1~L5 중 P0 범위).
## L1 크기(행 수=height, 열 수=width, 역할별 높이) / L2 허용 문자 / L3 모든 행에 통로(연속 비차단 셀) >= 3
## L4 이음매 행(0,1,22,23)이 전부 '.' (24행 청크만) / L5 하단 25%(row 18~23) 장애물 <= 18, 마커 개수 제한

const ALLOWED := ".#chSEGRDBP"
const MIN_PASSAGE := 3

static func expected_height(role: ChunkDef.Role) -> int:
	match role:
		ChunkDef.Role.PLAZA: return 12
		ChunkDef.Role.BOSS_ARENA: return 21
	return 24

static func lint(c: ChunkDef) -> Array[String]:
	var errs: Array[String] = []
	var id := String(c.id)
	# L1
	if c.height != expected_height(c.role):
		errs.append("%s L1 role height %d != %d" % [id, c.height, expected_height(c.role)])
	if c.grid.size() != c.height:
		errs.append("%s L1 rows %d != height %d" % [id, c.grid.size(), c.height])
	for r in c.grid.size():
		if c.grid[r].length() != c.width:
			errs.append("%s L1 row %d width %d != %d" % [id, r, c.grid[r].length(), c.width])
	if not errs.is_empty():
		return errs
	# L2
	for r in c.grid.size():
		for ch in c.grid[r]:
			if ALLOWED.find(ch) < 0:
				errs.append("%s L2 bad char '%s' row %d" % [id, ch, r])
	# L3
	for r in c.grid.size():
		var best := 0
		var run := 0
		for ch in c.grid[r]:
			if ChunkDef.bits_of(ch) & (ChunkDef.BIT_WALL | ChunkDef.BIT_COVER):
				run = 0
			else:
				run += 1
				best = maxi(best, run)
		if best < MIN_PASSAGE:
			errs.append("%s L3 row %d passage %d < %d" % [id, r, best, MIN_PASSAGE])
	# L4
	if c.height == 24:
		for r in [0, 1, 22, 23]:
			if c.grid[r] != ".".repeat(c.width):
				errs.append("%s L4 seam row %d not all floor" % [id, r])
		# L5 하단 25%
		var obst := 0
		for r in range(18, 24):
			for ch in c.grid[r]:
				if ChunkDef.bits_of(ch) != 0:
					obst += 1
		if obst > 18:
			errs.append("%s L5 bottom obstacles %d > 18" % [id, obst])
	if c.count_char("E") > 1:
		errs.append("%s L5 more than one E" % id)
	if c.count_char("G") > 0 and c.role != ChunkDef.Role.BOSS_ENTRY:
		errs.append("%s L5 G outside boss_entry" % id)
	return errs
