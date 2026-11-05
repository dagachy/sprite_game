class_name SpawnDirector extends RefCounted
## 스폰 결정 코어(level §5, economy §2.3). Node 비의존. 스폰 RNG 는 seed ^ 0x5F3D 로 분리 -
## 3택(리롤 포함)이 RNG 를 몇 번 소비하든 스폰 열은 같다.

const SEED_XOR: int = 0x5F3D

# ring_position 결과 source
const SRC_TOP := 0
const SRC_SIDE := 1

var bal: Balance
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var acc: float = 0.0
var grace_until: float = 0.0     # 이 월드 시각 전에는 스폰하지 않는다
var last_fail: int = 0           # spawn_fail 누적(로그용)

func _init(b: Balance, seed_value: int) -> void:
	bal = b
	rng.seed = seed_value ^ SEED_XOR
	grace_until = b.spawn_grace_start

func pressure(t: float) -> float:
	return bal.pressure_early if t < bal.pressure_split_t else bal.pressure_late

func target_n(t: float, slot_scale: float) -> float:
	return 4.0 * pressure(t) * slot_scale

## 구역 전환 후 유예 시작(economy §2.3: 2s)
func start_grace(t: float, sec: float) -> void:
	grace_until = maxf(grace_until, t + sec)

## 이번 틱에 링 스폰할 마릿수(0 또는 1). 과밀이면 연기하고 누적은 상한 2 로 캡.
func tick(dt: float, t: float, alive: int, slot_scale: float) -> int:
	if t < grace_until:
		return 0
	acc = minf(acc + target_n(t, slot_scale) / bal.t_life * dt, 2.0)
	if alive >= bal.defer_alive or alive >= bal.max_alive:
		return 0
	if acc >= 1.0:
		acc -= 1.0
		return 1
	return 0

func pick_kind() -> StringName:
	var total: float = 0.0
	for w in bal.spawn_weights:
		total += w
	var r: float = rng.randf() * total
	for i in bal.spawn_ids.size():
		r -= bal.spawn_weights[i]
		if r <= 0.0:
			return StringName(bal.spawn_ids[i])
	return StringName(bal.spawn_ids[0])

## 링 위치. 실패하면 z=-1. 성공 시 Vector3(x, y, source). strip 은 현재 scroll 이 반영돼 있어야 한다.
func ring_position(strip: WorldStrip, player: Vector2, flying: bool = false) -> Vector3:
	for attempt in 8:
		var side: bool = rng.randf() > bal.ring_top_ratio
		var x: float
		var y: float
		if side:
			x = WorldStrip.BORDER + 8.0 if rng.randf() < 0.5 else WorldStrip.WIDTH_PX - WorldStrip.BORDER - 8.0
			y = rng.randf_range(16.0, 154.0)
		else:
			x = WorldStrip.BORDER + 16.0 * float(rng.randi_range(0, 11)) + 8.0
			y = rng.randf_range(-32.0, -16.0)
		if valid_spawn(strip, x, y, player, flying):
			return Vector3(x, y, SRC_SIDE if side else SRC_TOP)
	last_fail += 1
	return Vector3(0, 0, -1)

## 스폰 가능 위치 판정(벽/엄폐/위험 위 금지, 반경 8px 안 벽 금지, 하단 25% 금지, 플레이어 96px).
func valid_spawn(strip: WorldStrip, x: float, y: float, player: Vector2, flying: bool = false) -> bool:
	if y >= 288.0:
		return false
	if player.distance_to(Vector2(x, y)) < bal.player_safe_radius:
		return false
	var b: int = strip.bits_screen(x, y)
	if b & (ChunkDef.BIT_WALL | ChunkDef.BIT_COVER | ChunkDef.BIT_HAZARD):
		return false
	if not flying and strip.circle_hits(x, y, 8.0, ChunkDef.BIT_WALL):
		return false
	return true

## S 마커 그룹의 개별 위치(앵커 + 반경 24 지터). 실패하면 앵커 자체.
func group_pos(strip: WorldStrip, ax: float, ay: float, player: Vector2) -> Vector2:
	for attempt in 6:
		var a: float = rng.randf() * TAU
		var d: float = rng.randf() * bal.group_jitter
		var p := Vector2(ax + cos(a) * d, ay + sin(a) * d)
		if p.x > WorldStrip.BORDER + 6.0 and p.x < WorldStrip.WIDTH_PX - WorldStrip.BORDER - 6.0 \
				and not (strip.bits_screen(p.x, p.y) & (ChunkDef.BIT_WALL | ChunkDef.BIT_COVER | ChunkDef.BIT_HAZARD)) \
				and not strip.circle_hits(p.x, p.y, 6.0, ChunkDef.BIT_WALL):
			return p
	return Vector2(ax, ay)
