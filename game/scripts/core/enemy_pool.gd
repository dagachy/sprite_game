class_name EnemyPool extends RefCounted
## 적 배열(SoA). hp<=0 은 사망 표시(같은 틱의 질의에서 건너뜀), reap() 이 swap-remove 로 정리한다.

# 타입 인덱스 -> Defs.ENEMIES id
const TYPE_IDS: Array[StringName] = [&"A1", &"A2", &"B1", &"B2", &"EL", &"BOSS"]
const T_A1 := 0
const T_A2 := 1
const T_B1 := 2
const T_B2 := 3
const T_EL := 4
const T_BOSS := 5

# 공통 상태 코드
const ST_EMERGE := 100   # 좌우 링 스폰의 0.4s 등장 표시(무적, 이동·접촉 없음)

var cap: int
var n: int = 0
var uid_counter: int = 0
var x: PackedFloat32Array = PackedFloat32Array()
var y: PackedFloat32Array = PackedFloat32Array()
var kx: PackedFloat32Array = PackedFloat32Array()   # 넉백 속도
var ky: PackedFloat32Array = PackedFloat32Array()
var hp: PackedFloat32Array = PackedFloat32Array()
var maxhp: PackedFloat32Array = PackedFloat32Array()
var spd: PackedFloat32Array = PackedFloat32Array()
var atk: PackedFloat32Array = PackedFloat32Array()
var rad: PackedFloat32Array = PackedFloat32Array()
var tm: PackedFloat32Array = PackedFloat32Array()
var aux: PackedFloat32Array = PackedFloat32Array()
var aux2: PackedFloat32Array = PackedFloat32Array()
var flash: PackedFloat32Array = PackedFloat32Array()
var hacc: PackedFloat32Array = PackedFloat32Array()
var ocd: PackedFloat32Array = PackedFloat32Array()   # 궤도 무기 재타격 쿨
var st: PackedInt32Array = PackedInt32Array()
var type: PackedInt32Array = PackedInt32Array()
var uid: PackedInt32Array = PackedInt32Array()
var xpv: PackedInt32Array = PackedInt32Array()
var kind: PackedInt32Array = PackedInt32Array()

func _init(capacity: int) -> void:
	cap = capacity
	x.resize(capacity); y.resize(capacity); kx.resize(capacity); ky.resize(capacity)
	hp.resize(capacity); maxhp.resize(capacity); spd.resize(capacity); atk.resize(capacity)
	rad.resize(capacity); tm.resize(capacity); aux.resize(capacity); aux2.resize(capacity)
	flash.resize(capacity); hacc.resize(capacity); ocd.resize(capacity)
	st.resize(capacity); type.resize(capacity); uid.resize(capacity); xpv.resize(capacity)
	kind.resize(capacity)

func clear() -> void:
	n = 0

## 새 적 추가. 가득 차면 -1.
func add(type_idx: int, px: float, py: float, hp_v: float, spd_v: float, atk_v: float,
		rad_v: float, xp_v: int, kind_v: int, state: int = 0) -> int:
	if n >= cap:
		return -1
	var i: int = n
	n += 1
	uid_counter += 1
	x[i] = px; y[i] = py; kx[i] = 0.0; ky[i] = 0.0
	hp[i] = hp_v; maxhp[i] = hp_v; spd[i] = spd_v; atk[i] = atk_v; rad[i] = rad_v
	tm[i] = 0.0; aux[i] = 0.0; aux2[i] = 0.0; flash[i] = 0.0; hacc[i] = 0.0; ocd[i] = 0.0
	st[i] = state; type[i] = type_idx; uid[i] = uid_counter; xpv[i] = xp_v; kind[i] = kind_v
	return i

func remove(i: int) -> void:
	n -= 1
	if i == n:
		return
	x[i] = x[n]; y[i] = y[n]; kx[i] = kx[n]; ky[i] = ky[n]
	hp[i] = hp[n]; maxhp[i] = maxhp[n]; spd[i] = spd[n]; atk[i] = atk[n]; rad[i] = rad[n]
	tm[i] = tm[n]; aux[i] = aux[n]; aux2[i] = aux2[n]; flash[i] = flash[n]; hacc[i] = hacc[n]
	ocd[i] = ocd[n]; st[i] = st[n]; type[i] = type[n]; uid[i] = uid[n]; xpv[i] = xpv[n]; kind[i] = kind[n]

func index_of_uid(u: int) -> int:
	for i in n:
		if uid[i] == u:
			return i
	return -1

func alive_count() -> int:
	var c: int = 0
	for i in n:
		if hp[i] > 0.0:
			c += 1
	return c
