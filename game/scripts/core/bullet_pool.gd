class_name BulletPool extends RefCounted
## 탄 배열(SoA). 노드 없음, 할당 없음. 렌더는 BattleView 가 배열을 직접 읽는다. swap-remove.

var cap: int
var n: int = 0
var x: PackedFloat32Array = PackedFloat32Array()
var y: PackedFloat32Array = PackedFloat32Array()
var vx: PackedFloat32Array = PackedFloat32Array()
var vy: PackedFloat32Array = PackedFloat32Array()
var dmg: PackedFloat32Array = PackedFloat32Array()
var life: PackedFloat32Array = PackedFloat32Array()
var pierce: PackedInt32Array = PackedInt32Array()
var flags: PackedInt32Array = PackedInt32Array()      # 1 = 벽 무시
var hit_a: PackedInt32Array = PackedInt32Array()      # 최근 맞힌 적 uid 2개(관통 중복 방지)
var hit_b: PackedInt32Array = PackedInt32Array()
var src: PackedInt32Array = PackedInt32Array()        # 무기 코드(통계용)

func _init(capacity: int) -> void:
	cap = capacity
	x.resize(capacity); y.resize(capacity); vx.resize(capacity); vy.resize(capacity)
	dmg.resize(capacity); life.resize(capacity)
	pierce.resize(capacity); flags.resize(capacity); hit_a.resize(capacity); hit_b.resize(capacity)
	src.resize(capacity)

func clear() -> void:
	n = 0

func add(px: float, py: float, pvx: float, pvy: float, d: float, lifetime: float,
		pierce_n: int = 0, flag: int = 0, source: int = 0) -> int:
	if n >= cap:
		return -1
	var i: int = n
	n += 1
	x[i] = px; y[i] = py; vx[i] = pvx; vy[i] = pvy
	dmg[i] = d; life[i] = lifetime; pierce[i] = pierce_n; flags[i] = flag
	hit_a[i] = -1; hit_b[i] = -1; src[i] = source
	return i

func remove(i: int) -> void:
	n -= 1
	if i != n:
		x[i] = x[n]; y[i] = y[n]; vx[i] = vx[n]; vy[i] = vy[n]
		dmg[i] = dmg[n]; life[i] = life[n]; pierce[i] = pierce[n]; flags[i] = flags[n]
		hit_a[i] = hit_a[n]; hit_b[i] = hit_b[n]; src[i] = src[n]
