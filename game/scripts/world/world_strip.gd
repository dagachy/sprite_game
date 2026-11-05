class_name WorldStrip extends RefCounted
## 청크를 위로 이어 붙인 세로 띠(level §1). 월드 y: 슬롯 0 이 [0,384], 다음 청크는 그 위(음수 y)에 붙는다.
## 화면 y = 월드 y + scroll. 지형은 청크 셀 비트마스크를 직접 조회한다(물리 엔진 미사용).

const TILE: float = 16.0
const BORDER: float = 12.0
const WIDTH_PX: float = 216.0
const BIT_EDGE := 128    # (P2 X2: 8은 소프트런칭 Gate 비트와 충돌해 128로 이동)경계/띠 밖. 벽으로 취급하지만 B1 돌진의 "하단 벽"과 "기둥" 구분에 쓴다.
const SOLID_ALL: int = ChunkDef.BIT_WALL | ChunkDef.BIT_COVER

class Placed extends RefCounted:
	var def: ChunkDef
	var origin_y: float = 0.0
	var height_px: float = 0.0
	var bits: PackedByteArray = PackedByteArray()
	var markers: Array[Dictionary] = []   # {ch, x, wy, fired}
	var slot: int = -1

var placed: Array[Placed] = []
var scroll: float = 0.0
var plaza: Placed
var entry: Placed
var arena: Placed
var top_y: float = 0.0   # 가장 위 청크의 위쪽 끝(월드 y)

func build(ids: Array[StringName], db: Dictionary) -> bool:
	placed.clear()
	var bottom: float = 384.0
	for i in ids.size():
		var def: ChunkDef = db.get(ids[i])
		if def == null:
			push_error("WorldStrip: unknown chunk %s" % ids[i])
			return false
		var p := Placed.new()
		p.def = def
		p.slot = i
		p.height_px = def.height * TILE
		p.origin_y = bottom - p.height_px
		bottom = p.origin_y
		p.bits.resize(def.width * def.height)
		for r in def.height:
			var row: String = def.grid[r]
			for c in def.width:
				var ch: String = row[c]
				p.bits[r * def.width + c] = ChunkDef.bits_of(ch)
				if ch in ["S", "E", "G", "R", "D", "B", "P"]:
					p.markers.append({"ch": ch, "x": BORDER + TILE * c + TILE * 0.5,
						"wy": p.origin_y + TILE * r + TILE * 0.5, "fired": false})
		placed.append(p)
		match def.role:
			ChunkDef.Role.PLAZA: plaza = p
			ChunkDef.Role.BOSS_ENTRY: entry = p
			ChunkDef.Role.BOSS_ARENA: arena = p
	top_y = bottom
	scroll = 0.0
	return true

## 월드 좌표 셀 비트. 띠 밖과 좌우 경계는 BIT_WALL|BIT_EDGE.
func bits_world(x: float, wy: float) -> int:
	if x < BORDER or x >= WIDTH_PX - BORDER or wy < top_y or wy >= 384.0:
		return ChunkDef.BIT_WALL | BIT_EDGE
	for p in placed:
		if wy >= p.origin_y and wy < p.origin_y + p.height_px:
			var c: int = int((x - BORDER) / TILE)
			var r: int = int((wy - p.origin_y) / TILE)
			return p.bits[r * p.def.width + c]
	return 0

func bits_screen(x: float, sy: float) -> int:
	return bits_world(x, sy - scroll)

## 원(화면 좌표)이 mask 비트 셀과 겹치는가. 셀은 AABB 로 본다.
func circle_hits(x: float, sy: float, r: float, mask: int) -> bool:
	var wy: float = sy - scroll
	var c0: int = floori((x - r - BORDER) / TILE)
	var c1: int = floori((x + r - BORDER) / TILE)
	var r0: int = floori((wy - r) / TILE)
	var r1: int = floori((wy + r) / TILE)
	for rr in range(r0, r1 + 1):
		for cc in range(c0, c1 + 1):
			var cx: float = BORDER + cc * TILE + TILE * 0.5
			var cy: float = rr * TILE + TILE * 0.5
			# 셀 중심에서 비트 조회(행 경계가 청크마다 16 배수이므로 rr*16 정렬 유지)
			if bits_world(cx, cy) & mask:
				var nx: float = clampf(x, cx - TILE * 0.5, cx + TILE * 0.5)
				var ny: float = clampf(wy, cy - TILE * 0.5, cy + TILE * 0.5)
				var dx: float = x - nx
				var dy: float = wy - ny
				if dx * dx + dy * dy < r * r:
					return true
	return false

## 두 화면 점 사이를 4px 간격으로 샘플링해 mask 셀을 지나는지 본다.
func segment_blocked(x0: float, y0: float, x1: float, y1: float, mask: int) -> bool:
	var dx: float = x1 - x0
	var dy: float = y1 - y0
	var dist: float = sqrt(dx * dx + dy * dy)
	var steps: int = maxi(int(dist / 4.0), 1)
	for i in range(1, steps + 1):
		var f: float = float(i) / float(steps)
		if bits_screen(x0 + dx * f, y0 + dy * f) & mask:
			return true
	return false

func chunk_at_world(wy: float) -> Placed:
	for p in placed:
		if wy >= p.origin_y and wy < p.origin_y + p.height_px:
			return p
	return null

## 화면 y 범위에 걸린 청크 목록(렌더용). out 을 재사용한다.
func visible(out: Array[Placed], top: float, bottom: float) -> void:
	out.clear()
	for p in placed:
		var s0: float = p.origin_y + scroll
		if s0 < bottom and s0 + p.height_px > top:
			out.append(p)
