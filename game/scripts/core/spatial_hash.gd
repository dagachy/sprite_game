class_name SpatialHash extends RefCounted
## 32px 셀 공간 해시(탄↔적, 무기 범위 질의). 연결 리스트 버킷, 재빌드는 매 틱 1회, 할당 없음.

const CELL: float = 32.0
const OX: float = -64.0
const OY: float = -96.0
const COLS: int = 14
const ROWS: int = 20

var _head: PackedInt32Array = PackedInt32Array()
var _next: PackedInt32Array = PackedInt32Array()

func _init(capacity: int = 256) -> void:
	_head.resize(COLS * ROWS)
	_next.resize(capacity)

func rebuild(xs: PackedFloat32Array, ys: PackedFloat32Array, hp: PackedFloat32Array, n: int) -> void:
	_head.fill(-1)
	if _next.size() < n:
		_next.resize(n)
	for i in n:
		if hp[i] <= 0.0:
			continue
		var c: int = _cell(xs[i], ys[i])
		_next[i] = _head[c]
		_head[c] = i

func _cell(x: float, y: float) -> int:
	var cx: int = clampi(int((x - OX) / CELL), 0, COLS - 1)
	var cy: int = clampi(int((y - OY) / CELL), 0, ROWS - 1)
	return cy * COLS + cx

## 반경 r 이내 후보(셀 단위 근사 + 거리 필터)를 out 에 채우고 개수를 돌려준다.
func query(x: float, y: float, r: float, xs: PackedFloat32Array, ys: PackedFloat32Array,
		out: PackedInt32Array) -> int:
	var x0: int = clampi(int((x - r - OX) / CELL), 0, COLS - 1)
	var x1: int = clampi(int((x + r - OX) / CELL), 0, COLS - 1)
	var y0: int = clampi(int((y - r - OY) / CELL), 0, ROWS - 1)
	var y1: int = clampi(int((y + r - OY) / CELL), 0, ROWS - 1)
	var cnt: int = 0
	var cap: int = out.size()
	var r2: float = r * r
	for cy in range(y0, y1 + 1):
		for cx in range(x0, x1 + 1):
			var i: int = _head[cy * COLS + cx]
			while i >= 0:
				var dx: float = xs[i] - x
				var dy: float = ys[i] - y
				if dx * dx + dy * dy <= r2 and cnt < cap:
					out[cnt] = i
					cnt += 1
				i = _next[i]
	return cnt
