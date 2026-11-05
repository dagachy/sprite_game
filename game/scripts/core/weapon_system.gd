class_name WeaponSystem extends RefCounted
## 무기 4종(W01 호 / W02 단발·산탄 / W03 궤도 / W04 지뢰) + 진화형(E01 전방위, E02 산탄 연사).
## 정적 함수만 둔다. 상태는 Battle 이 가진다(순환 참조 방지).

const SRC_W01 := 0
const SRC_W02 := 1
const SRC_W03 := 2
const SRC_W04 := 3
const SRC_E01 := 4
const SRC_E02 := 5
const BULLET_R := 3.0
const AIM_RANGE := 200.0

static func active_def(b: Battle, id: StringName) -> Dictionary:
	if b.offer_state.evolved.has(id):
		var rid: StringName = Defs.EVOLUTIONS[id]["result"]
		return Defs.weapon_level_def(rid, 1)
	return Defs.weapon_level_def(id, int(b.offer_state.weapons[id]))

static func active_id(b: Battle, id: StringName) -> StringName:
	if b.offer_state.evolved.has(id):
		return Defs.EVOLUTIONS[id]["result"]
	return id

static func rate(b: Battle) -> float:
	var r: float = 1.0 + b.passive_val(&"P02")
	if b.cover_bonus:
		r *= float(Defs.CLASSES[b.class_id]["cover_haste"])
	return r

static func update(b: Battle, dt: float) -> void:
	var e: EnemyPool = b.enemies
	b.cover_bonus = (b.strip.bits_screen(b.px, b.py - WorldStrip.TILE) & ChunkDef.BIT_COVER) != 0
	var ti: int = b.aim.update(dt, b.px, b.py, e.x, e.y, e.hp, e.uid, e.n, AIM_RANGE, -4.0)
	b.aim_idx = ti
	var rt: float = rate(b)
	b.orb_n = 0
	for id in b.weapon_order:
		var def: Dictionary = active_def(b, id)
		var aid: StringName = active_id(b, id)
		var kind: StringName = Defs.WEAPONS[aid]["kind"]
		match kind:
			&"arc": _arc(b, id, aid, def, dt, rt, ti)
			&"bolt": _bolt(b, id, aid, def, dt, rt, ti)
			&"orbit": _orbit(b, aid, def, dt)
			&"mine": _mine(b, id, aid, def, dt, rt)
	_swing_queue(b, dt)
	_update_mines(b, dt)

static func _src(aid: StringName) -> int:
	match aid:
		&"W01": return SRC_W01
		&"W02": return SRC_W02
		&"W03": return SRC_W03
		&"W04": return SRC_W04
		&"E01": return SRC_E01
		&"E02": return SRC_E02
	return Battle.SRC_OTHER

# --- W01 / E01 ---------------------------------------------------------

static func _arc(b: Battle, id: StringName, aid: StringName, def: Dictionary, dt: float, rt: float, ti: int) -> void:
	var cd: float = float(b.wcd.get(id, 0.0)) - dt
	b.wcd[id] = cd
	if cd > 0.0 or ti < 0:
		return
	var e: EnemyPool = b.enemies
	var range_px: float = float(def["range"])
	var dx: float = e.x[ti] - b.px
	var dy: float = e.y[ti] - b.py
	if sqrt(dx * dx + dy * dy) > range_px + e.rad[ti] + 8.0:
		return
	var ang: float = atan2(dy, dx)
	b.wcd[id] = float(def["cd"]) / rt
	do_swing(b, aid, def, ang)
	if int(def["swings"]) >= 2:
		b.swing_q.append([0.2, ang + PI, aid])

static func do_swing(b: Battle, aid: StringName, def: Dictionary, ang: float) -> void:
	var e: EnemyPool = b.enemies
	var range_px: float = float(def["range"])
	var arc: float = deg_to_rad(float(def["arc"]))
	var evolved: bool = Defs.WEAPONS[aid].has("evolved")
	var dmg: float = float(def["dmg"])
	var kb: float = float(def["kb"])
	var n: int = b.hash.query(b.px, b.py, range_px + 26.0, e.x, e.y, b._qbuf)
	for k in n:
		var j: int = b._qbuf[k]
		if e.hp[j] <= 0.0:
			continue
		var dx: float = e.x[j] - b.px
		var dy: float = e.y[j] - b.py
		var d: float = sqrt(dx * dx + dy * dy)
		if d > range_px + e.rad[j]:
			continue
		if arc < TAU - 0.01 and d > 0.001:
			var da: float = absf(angle_difference(ang, atan2(dy, dx)))
			if da > arc * 0.5 + asin(clampf(e.rad[j] / maxf(d, e.rad[j]), 0.0, 1.0)):
				continue
		if not evolved and b.strip.segment_blocked(b.px, b.py, e.x[j], e.y[j], ChunkDef.BIT_WALL):
			continue
		b.damage_enemy(j, dmg, _src(aid))
		b.knock(j, dx, dy, kb)
	b.slashes.append({"x": b.px, "y": b.py, "ang": ang, "arc": arc, "range": range_px, "life": 0.12, "max": 0.12})
	if b.slashes.size() > 8:
		b.slashes.remove_at(0)

static func _swing_queue(b: Battle, dt: float) -> void:
	var i: int = 0
	while i < b.swing_q.size():
		b.swing_q[i][0] = float(b.swing_q[i][0]) - dt
		if float(b.swing_q[i][0]) <= 0.0:
			var aid: StringName = b.swing_q[i][2]
			var ang: float = float(b.swing_q[i][1])
			var base: StringName = aid
			for wid in Defs.EVOLUTIONS.keys():
				if Defs.EVOLUTIONS[wid]["result"] == aid:
					base = wid
			var def: Dictionary = active_def(b, base) if b.offer_state.weapons.has(base) else Defs.weapon_level_def(aid, 1)
			do_swing(b, aid, def, ang)
			b.swing_q.remove_at(i)
		else:
			i += 1

# --- W02 / E02 ---------------------------------------------------------

static func _bolt(b: Battle, id: StringName, aid: StringName, def: Dictionary, dt: float, rt: float, ti: int) -> void:
	var cd: float = float(b.wcd.get(id, 0.0)) - dt
	b.wcd[id] = cd
	if cd > 0.0 or ti < 0:
		return
	var e: EnemyPool = b.enemies
	b.wcd[id] = float(def["cd"]) / rt
	var ang: float = atan2(e.y[ti] - b.py, e.x[ti] - b.px)
	var count: int = int(def["count"])
	var fan: float = deg_to_rad(float(def["fan"]))
	var speed: float = float(def["speed"])
	var life: float = float(def["range"]) / speed
	var flag: int = 1 if def.get("ignore_walls", false) else 0
	for k in count:
		var off: float = (float(k) - float(count - 1) * 0.5)
		var a: float = ang + off * fan
		var ox: float = 0.0
		var oy: float = 0.0
		if fan == 0.0 and count > 1:
			ox = -sin(a) * off * 5.0
			oy = cos(a) * off * 5.0
		b.abul.add(b.px + ox, b.py + oy, cos(a) * speed, sin(a) * speed, float(def["dmg"]), life,
				int(def["pierce"]), flag, _src(aid))

# --- W03 ---------------------------------------------------------------

static func _orbit(b: Battle, aid: StringName, def: Dictionary, dt: float) -> void:
	var e: EnemyPool = b.enemies
	var count: int = int(def["count"])
	var radius: float = float(def["radius"])
	b.orbit_angle = fmod(b.orbit_angle + TAU / float(def["period"]) * dt, TAU)
	b.orb_n = count
	b.orb_r = radius
	var block: bool = bool(def["block"])
	for k in count:
		var a: float = b.orbit_angle + TAU * float(k) / float(count)
		var ox: float = b.px + cos(a) * radius
		var oy: float = b.py + sin(a) * radius
		var n: int = b.hash.query(ox, oy, 5.0 + 26.0, e.x, e.y, b._qbuf)
		for q in n:
			var j: int = b._qbuf[q]
			if e.hp[j] <= 0.0 or e.ocd[j] > 0.0 or e.st[j] == EnemyPool.ST_EMERGE:
				continue
			var dx: float = e.x[j] - ox
			var dy: float = e.y[j] - oy
			if dx * dx + dy * dy <= (e.rad[j] + 5.0) * (e.rad[j] + 5.0):
				e.ocd[j] = float(def["rehit"])
				b.damage_enemy(j, float(def["dmg"]), _src(aid))
				b.knock(j, dx, dy, 8.0)
		if block:
			var i: int = 0
			while i < b.ebul.n:
				var bx: float = b.ebul.x[i] - ox
				var by: float = b.ebul.y[i] - oy
				if bx * bx + by * by <= 64.0:
					b.ebul.remove(i)
				else:
					i += 1

# --- W04 ---------------------------------------------------------------

static func _mine(b: Battle, id: StringName, aid: StringName, def: Dictionary, dt: float, rt: float) -> void:
	var cd: float = float(b.wcd.get(id, 0.0)) - dt
	b.wcd[id] = cd
	if cd > 0.0 or b.mn >= int(def["max"]) or b.mn >= Battle.MINE_CAP:
		return
	b.wcd[id] = float(def["cd"]) / rt
	b.mx[b.mn] = b.px
	b.my[b.mn] = b.py
	b.mt[b.mn] = 0.0
	b.ms[b.mn] = 0
	b.mn += 1

static func _blast(b: Battle, x: float, y: float, def: Dictionary, aid: StringName) -> void:
	var e: EnemyPool = b.enemies
	var r: float = float(def["blast"])
	var n: int = b.hash.query(x, y, r + 26.0, e.x, e.y, b._qbuf)
	for q in n:
		var j: int = b._qbuf[q]
		if e.hp[j] <= 0.0:
			continue
		var dx: float = e.x[j] - x
		var dy: float = e.y[j] - y
		if dx * dx + dy * dy <= (r + e.rad[j]) * (r + e.rad[j]):
			b.damage_enemy(j, float(def["dmg"]), _src(aid))
	b.booms.append({"x": x, "y": y, "r": r, "life": 0.2, "max": 0.2, "kind": 0})
	if b.booms.size() > 12:
		b.booms.remove_at(0)

static func _update_mines(b: Battle, dt: float) -> void:
	if b.mn == 0:
		return
	var e: EnemyPool = b.enemies
	var id: StringName = &"W04"
	if not b.offer_state.weapons.has(id):
		b.mn = 0
		return
	var def: Dictionary = active_def(b, id)
	var i: int = 0
	while i < b.mn:
		var remove: bool = false
		match b.ms[i]:
			0:
				var trig: float = float(def["trigger"])
				var n: int = b.hash.query(b.mx[i], b.my[i], trig + 26.0, e.x, e.y, b._qbuf)
				var hit: bool = false
				for q in n:
					var j: int = b._qbuf[q]
					if e.hp[j] <= 0.0:
						continue
					var dx: float = e.x[j] - b.mx[i]
					var dy: float = e.y[j] - b.my[i]
					if dx * dx + dy * dy <= (trig + e.rad[j]) * (trig + e.rad[j]):
						hit = true
						break
				if hit:
					_blast(b, b.mx[i], b.my[i], def, id)
					if bool(def["double"]):
						b.ms[i] = 1
						b.mt[i] = 0.3
					elif bool(def["residual"]):
						b.ms[i] = 2
						b.mt[i] = 2.0
					else:
						remove = true
			1:
				b.mt[i] -= dt
				if b.mt[i] <= 0.0:
					_blast(b, b.mx[i], b.my[i], def, id)
					if bool(def["residual"]):
						b.ms[i] = 2
						b.mt[i] = 2.0
					else:
						remove = true
			2:
				b.mt[i] -= dt
				var r: float = float(def["blast"])
				var n2: int = b.hash.query(b.mx[i], b.my[i], r + 26.0, e.x, e.y, b._qbuf)
				for q in n2:
					var j2: int = b._qbuf[q]
					if e.hp[j2] <= 0.0:
						continue
					var dx2: float = e.x[j2] - b.mx[i]
					var dy2: float = e.y[j2] - b.my[i]
					if dx2 * dx2 + dy2 * dy2 <= (r + e.rad[j2]) * (r + e.rad[j2]):
						b.damage_enemy(j2, float(def["dmg"]) * 0.6 * dt, SRC_W04)
				if b.mt[i] <= 0.0:
					remove = true
		if remove or b.my[i] > 420.0:
			b.mn -= 1
			b.mx[i] = b.mx[b.mn]; b.my[i] = b.my[b.mn]; b.mt[i] = b.mt[b.mn]; b.ms[i] = b.ms[b.mn]
		else:
			i += 1

# --- 아군 탄 -----------------------------------------------------------

static func update_bullets(b: Battle, dt: float) -> void:
	var e: EnemyPool = b.enemies
	var ab: BulletPool = b.abul
	var i: int = 0
	while i < ab.n:
		var nx: float = ab.x[i] + ab.vx[i] * dt
		var ny: float = ab.y[i] + ab.vy[i] * dt
		ab.x[i] = nx
		ab.y[i] = ny
		ab.life[i] -= dt
		var dead: bool = ab.life[i] <= 0.0 or nx < 0.0 or nx > 216.0 or ny < -24.0 or ny > 410.0
		if not dead and (ab.flags[i] & 1) == 0 and (b.strip.bits_screen(nx, ny) & ChunkDef.BIT_WALL):
			dead = true
		if not dead:
			var n: int = b.hash.query(nx, ny, BULLET_R + 26.0, e.x, e.y, b._qbuf)
			for q in n:
				var j: int = b._qbuf[q]
				if e.hp[j] <= 0.0 or e.st[j] == EnemyPool.ST_EMERGE:
					continue
				var u: int = e.uid[j]
				if u == ab.hit_a[i] or u == ab.hit_b[i]:
					continue
				var dx: float = e.x[j] - nx
				var dy: float = e.y[j] - ny
				var rr: float = e.rad[j] + BULLET_R
				if dx * dx + dy * dy > rr * rr:
					continue
				b.damage_enemy(j, ab.dmg[i], ab.src[i])
				b.knock(j, ab.vx[i], ab.vy[i], 4.0)
				if ab.pierce[i] > 0:
					ab.pierce[i] -= 1
					ab.hit_b[i] = ab.hit_a[i]
					ab.hit_a[i] = u
				else:
					dead = true
					break
		if dead:
			ab.remove(i)
		else:
			i += 1
