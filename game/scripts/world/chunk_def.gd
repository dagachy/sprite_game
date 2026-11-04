class_name ChunkDef extends Resource
## 청크 그리드 데이터 (level §2). 원본은 data/chunks/*.txt.
## 파일 형식: "key: value" 헤더 줄들, "---" 구분선, 그리드 행들. '#' 로 시작하는 헤더 줄은 주석.

enum Role { OPEN, CHOKE, COVER, HAZARD, PLAZA, BOSS_ENTRY, BOSS_ARENA, TREASURE, TRAP }

const BIT_WALL := 1
const BIT_COVER := 2
const BIT_HAZARD := 4

@export var id: StringName = &""
@export var role: Role = Role.OPEN
@export var grid: PackedStringArray = []
@export var width: int = 12
@export var height: int = 24
@export var tags: PackedStringArray = []
@export var difficulty: int = 1
@export var weight: float = 1.0
@export var spawn_budget: int = 4

static func parse(text: String) -> ChunkDef:
	var c := ChunkDef.new()
	var in_grid := false
	var rows := PackedStringArray()
	for raw in text.split("\n"):
		var line := raw.strip_edges(false, true)
		if line.ends_with("\r"):
			line = line.trim_suffix("\r")
		if not in_grid:
			if line.strip_edges() == "---":
				in_grid = true
				continue
			if line.strip_edges() == "" or line.begins_with("#"):
				continue
			var idx := line.find(":")
			if idx < 0:
				continue
			var k := line.substr(0, idx).strip_edges()
			var v := line.substr(idx + 1).strip_edges()
			match k:
				"id": c.id = StringName(v)
				"role": c.role = Role.get(v, Role.OPEN)
				"width": c.width = int(v)
				"height": c.height = int(v)
				"tags": c.tags = PackedStringArray(v.split(" ", false))
				"difficulty": c.difficulty = int(v)
				"weight": c.weight = float(v)
				"spawn_budget": c.spawn_budget = int(v)
		else:
			if line.strip_edges() == "":
				continue
			rows.append(line)
	c.grid = rows
	return c

func count_char(ch: String) -> int:
	var n := 0
	for row in grid:
		n += row.count(ch)
	return n

## 셀 비트(벽/엄폐/위험). 마커 아래는 바닥.
static func bits_of(ch: String) -> int:
	match ch:
		"#": return BIT_WALL
		"c": return BIT_COVER
		"h": return BIT_HAZARD
	return 0
