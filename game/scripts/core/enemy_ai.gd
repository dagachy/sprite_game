class_name EnemyAI extends RefCounted
## 적 AI(SWARM / EXPLODER / SHOOTER / HEAVY / BOSS). 상태는 EnemyPool 의 st/tm/aux 필드에 둔다.
## 보스 필드 재사용: kx = 돌진 잠금 x, aux = 패턴 카운터, aux2 = 홈 y, hacc = 2페이즈 플래그, ky = 남은 탄막 횟수.

# 보스 상태
const BS_INTRO := 10
const BS_IDLE := 11
const BS_B1_TELE := 12
const BS_B1_CHARGE := 13
const BS_STUN := 14
const BS_RETURN := 15
const BS_REST := 16
const BS_B2_TELE := 17
const BS_B2_FIRE := 18
const BS_P2_PAUSE := 19

static func update(b: Battle, dt: float) -> void:
	var e: EnemyPool = b.enemies
	var bal: Balance = b.bal
	var strip: WorldStrip = b.strip
	var decay: float = maxf(0.0, 1.0 - 12.0 * dt)
	for i in e.n:
		if e.hp[i] <= 0.0:
			continue
		if e.flash[i] > 0.0:
			e.flash[i] = maxf(e.flash[i] - dt, 0.0)
		if e.ocd[i] > 0.0:
			e.ocd[i] = maxf(e.ocd[i] - dt, 0.0)
		if e.st[i] == EnemyPool.ST_EMERGE:
			e.tm[i] -= dt
			if e.tm[i] <= 0.0:
				e.st[i] = 0
			continue
		# 넉백
		if e.kx[i] != 0.0 or e.ky[i] != 0.0:
			if e.type[i] != EnemyPool.T_BOSS:
				_slide(strip, e, i, e.kx[i] * dt, e.ky[i] * dt)
				e.kx[i] *= decay
				e.ky[i] *= decay
				if absf(e.kx[i]) < 1.0 and absf(e.ky[i]) < 1.0:
					e.kx[i] = 0.0
					e.ky[i] = 0.0
		if e.y[i] > 430.0 or e.x[i] < -40.0 or e.x[i] > 256.0:
			e.hp[i] = -1.0   # 화면 밖 이탈(보상 없음)
			continue
		var dx: float = b.px - e.x[i]
		var dy: float = b.py - e.y[i]
		var dist: float = sqrt(dx * dx + dy * dy)
		var nx: float = dx / maxf(dist, 0.001)
		var ny: float = dy / maxf(dist, 0.001)
		match e.kind[i]:
			Defs.K_SWARM:
				_slide(strip, e, i, nx * e.spd[i] * dt, ny * e.spd[i] * dt)
			Defs.K_EXPLODER:
				_exploder(b, i, dt, dist, nx, ny)
			Defs.K_SHOOTER:
				_shooter(b, i, dt, dist, nx, ny)
			Defs.K_HEAVY:
				_heavy(b, i, dt, dist, nx, ny)
			Defs.K_BOSS:
				_boss(b, i, dt, dist, nx, ny)

## 벽·엄폐를 피해 축별로 이동
static func _slide(strip: WorldStrip, e: EnemyPool, i: int, mx: float, my: float) -> void:
	var r: float = e.rad[i] * 0.7
	var nx: float = e.x[i] + mx
	if not strip.circle_hits(nx, e.y[i], r, Battle.SOLID):
		e.x[i] = nx
	var ny: float = e.y[i] + my
	if not strip.circle_hits(e.x[i], ny, r, Battle.SOLID):
		e.y[i] = ny

static func _exploder(b: Battle, i: int, dt: float, dist: float, nx: float, ny: float) -> void:
	var e: EnemyPool = b.enemies
	var d: Dictionary = Defs.ENEMIES[&"A2"]
	if e.st[i] == 0:
		_slide(b.strip, e, i, nx * e.spd[i] * dt, ny * e.spd[i] * dt)
		if dist < float(d["trigger"]):
			e.st[i] = 1
			e.tm[i] = float(d["telegraph"])
	else:
		e.tm[i] -= dt
		if e.tm[i] <= 0.0:
			var br: float = float(d["blast_radius"])
			b.booms.append({"x": e.x[i], "y": e.y[i], "r": br, "life": 0.25, "max": 0.25, "kind": 1})
			if dist <= br + b.bal.player_radius:
				b.hurt(e.atk[i], &"contact", false, false, &"blast")
			e.hp[i] = 0.0
			b._kill(i, Battle.SRC_OTHER)
			e.hp[i] = -1.0

static func _shooter(b: Battle, i: int, dt: float, dist: float, nx: float, ny: float) -> void:
	var e: EnemyPool = b.enemies
	var d: Dictionary = Defs.ENEMIES[&"B1"]
	var hold: float = float(d["hold_dist"])
	if e.st[i] == 0:
		if dist > hold:
			_slide(b.strip, e, i, nx * e.spd[i] * dt, ny * e.spd[i] * dt)
		elif dist < hold * 0.6:
			_slide(b.strip, e, i, -nx * e.spd[i] * dt, -ny * e.spd[i] * dt)
		e.tm[i] -= dt
		if e.tm[i] <= 0.0 and e.y[i] > 8.0 and dist < hold + 60.0:
			e.st[i] = 1
			e.aux[i] = float(d["aim"])
	else:
		e.aux[i] -= dt
		if e.aux[i] <= 0.0:
			b.fire_enemy_bullet(e.x[i], e.y[i], nx, ny, float(d["bullet_speed"]), e.atk[i])
			e.st[i] = 0
			e.tm[i] = float(d["cooldown"])

static func _heavy(b: Battle, i: int, dt: float, dist: float, nx: float, ny: float) -> void:
	var e: EnemyPool = b.enemies
	var d: Dictionary = Defs.ENEMIES[&"EL"]
	match e.st[i]:
		0:
			_slide(b.strip, e, i, nx * e.spd[i] * dt, ny * e.spd[i] * dt)
			if dist < float(d["slam_trigger"]):
				e.st[i] = 1
				e.tm[i] = float(d["telegraph"])
		1:
			e.tm[i] -= dt
			if e.tm[i] <= 0.0:
				var sr: float = float(d["slam_radius"])
				b.booms.append({"x": e.x[i], "y": e.y[i], "r": sr, "life": 0.25, "max": 0.25, "kind": 2})
				if dist <= sr + b.bal.player_radius:
					b.hurt(float(d["slam_dmg"]) * b.atk_scale(), &"contact", false, false, EnemyPool.TYPE_IDS[e.type[i]])
				e.st[i] = 2
				e.tm[i] = float(d["recover"])
		2:
			e.tm[i] -= dt
			if e.tm[i] <= 0.0:
				e.st[i] = 0

# ----------------------------------------------------------------------
# 보스(층 보스: B1 돌진, B2 탄 부채)
# ----------------------------------------------------------------------

static func boss_damage_filter(b: Battle, i: int, d: float) -> float:
	var s: int = b.enemies.st[i]
	if s == BS_INTRO or s == BS_P2_PAUSE:
		return 0.0
	if s == BS_STUN:
		return d * 2.0
	return d

static func _p2(e: EnemyPool, i: int) -> bool:
	return e.hacc[i] > 0.5

static func _boss(b: Battle, i: int, dt: float, dist: float, nx: float, ny: float) -> void:
	var e: EnemyPool = b.enemies
	var bal: Balance = b.bal
	b.boss_tele_kind = 0
	var arena_bottom: float = b.strip.arena.origin_y + b.strip.scroll + b.strip.arena.height_px
	# 2페이즈 전환
	if not _p2(e, i) and e.hp[i] <= e.maxhp[i] * bal.boss_phase2_ratio and e.st[i] != BS_INTRO:
		e.hacc[i] = 1.0
		e.st[i] = BS_P2_PAUSE
		e.tm[i] = bal.boss_phase2_pause
		b.log_event.emit("boss_phase2", {"t": b.t})
	var mult: float = bal.boss_phase2_speed if _p2(e, i) else 1.0
	_boss_minions(b, i, dt)
	match e.st[i]:
		BS_INTRO, BS_P2_PAUSE:
			e.tm[i] -= dt
			if e.tm[i] <= 0.0:
				e.st[i] = BS_IDLE
				e.tm[i] = bal.boss_phase2_gap if _p2(e, i) else bal.boss_idle_gap
		BS_IDLE:
			e.tm[i] -= dt
			if e.tm[i] <= 0.0:
				var pat: int = int(e.aux[i]) % 2
				e.aux[i] += 1.0
				if pat == 0:
					var col: int = floori((b.px - WorldStrip.BORDER) / WorldStrip.TILE)
					e.kx[i] = WorldStrip.BORDER + col * WorldStrip.TILE + WorldStrip.TILE * 0.5
					e.st[i] = BS_B1_TELE
					e.tm[i] = bal.b1_telegraph
					if b.early_run:
						b.hint.emit("hint.pillar")
				else:
					e.st[i] = BS_B2_TELE
					e.tm[i] = bal.b2_telegraph
		BS_B1_TELE:
			e.tm[i] -= dt
			var mxs: float = 140.0 * dt
			e.x[i] += clampf(e.kx[i] - e.x[i], -mxs, mxs)
			b.boss_tele_kind = 1
			b.boss_tele_x = e.kx[i]
			b.boss_tele_t = 1.0 - clampf(e.tm[i] / bal.b1_telegraph, 0.0, 1.0)
			if e.tm[i] <= 0.0:
				e.st[i] = BS_B1_CHARGE
		BS_B1_CHARGE:
			b.boss_tele_kind = 1
			b.boss_tele_x = e.kx[i]
			b.boss_tele_t = 1.0
			var step: float = bal.b1_speed * mult * dt
			var ny2: float = e.y[i] + step
			var front: float = ny2 + e.rad[i]
			var hit_wall: bool = false
			var pillar: bool = false
			if front >= arena_bottom - 4.0:
				hit_wall = true
			else:
				for ox in [-14.0, -7.0, 0.0, 7.0, 14.0]:
					if b.strip.bits_screen(e.x[i] + ox, front) & ChunkDef.BIT_WALL:
						hit_wall = true
						pillar = true
						break
			if hit_wall:
				e.st[i] = BS_STUN
				e.tm[i] = bal.b1_stun_pillar if pillar else bal.b1_stun_wall
				b.booms.append({"x": e.x[i], "y": e.y[i] + e.rad[i], "r": bal.b1_shock_radius, "life": 0.25, "max": 0.25, "kind": 2})
				if Vector2(b.px - e.x[i], b.py - (e.y[i] + e.rad[i])).length() <= bal.b1_shock_radius:
					b.hurt(bal.b1_shock_dmg, &"contact", false, false, &"boss")
				b.request_shake(bal.shake_boss_hit)
				if pillar:
					b.log_event.emit("b1_stun_pillar", {"t": b.t})
					b.pillar_stuns += 1
			else:
				e.y[i] = ny2
		BS_STUN:
			e.tm[i] -= dt
			if e.tm[i] <= 0.0:
				e.st[i] = BS_RETURN
		BS_RETURN:
			e.y[i] = maxf(e.y[i] - 90.0 * dt, e.aux2[i])
			e.x[i] += clampf(108.0 - e.x[i], -60.0 * dt, 60.0 * dt)
			if e.y[i] <= e.aux2[i] + 0.01:
				e.st[i] = BS_REST
				e.tm[i] = bal.b1_rest
		BS_REST:
			e.tm[i] -= dt
			if e.tm[i] <= 0.0:
				e.st[i] = BS_IDLE
				e.tm[i] = bal.boss_phase2_gap if _p2(e, i) else bal.boss_idle_gap
		BS_B2_TELE:
			e.tm[i] -= dt
			b.boss_tele_kind = 2
			b.boss_tele_x = e.x[i]
			b.boss_tele_t = 1.0 - clampf(e.tm[i] / bal.b2_telegraph, 0.0, 1.0)
			if e.tm[i] <= 0.0:
				e.st[i] = BS_B2_FIRE
				e.ky[i] = float(bal.b2_volleys)
				e.tm[i] = 0.0
		BS_B2_FIRE:
			e.tm[i] -= dt
			if e.tm[i] <= 0.0:
				var base: float = atan2(ny, nx)
				var fan: float = deg_to_rad(bal.b2_fan_deg)
				for k in 3:
					var a: float = base + (k - 1) * fan
					b.fire_enemy_bullet(e.x[i], e.y[i], cos(a), sin(a), bal.b2_bullet_speed * mult, bal.b2_bullet_dmg)
				e.ky[i] -= 1.0
				e.tm[i] = bal.b2_interval
				if e.ky[i] <= 0.0:
					e.st[i] = BS_REST
					e.tm[i] = bal.b2_rest

static func _boss_minions(b: Battle, i: int, dt: float) -> void:
	var e: EnemyPool = b.enemies
	if e.st[i] == BS_INTRO:
		return
	b.minion_t -= dt
	if b.minion_t > 0.0:
		return
	b.minion_t = b.bal.minion_interval
	if e.alive_count() - 1 >= b.bal.minion_max:
		return
	var top: float = b.strip.arena.origin_y + b.strip.scroll
	var x: float = WorldStrip.BORDER + 16.0 * float(b.spawner.rng.randi_range(0, 11)) + 8.0
	var y: float = top + 24.0
	if b.strip.bits_screen(x, y) & Battle.SOLID == 0:
		b.add_enemy(EnemyPool.T_A1, x, y)
