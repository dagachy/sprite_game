extends Node2D
## Battle 상태를 _draw 로 그리는 단일 노드 렌더러(탄·적·보석은 개별 노드 없음). 아트는 팔레트 회색 박스 플레이스홀더.
## 계열 구분: A 계열 = 원형 + 윗점, B 계열 = 사각형 + 1px 마크(art, market-review P8).

var battle: Battle
var _vis: Array[WorldStrip.Placed] = []
var show_markers: bool = false

func _draw() -> void:
	if battle == null:
		return
	var b: Battle = battle
	draw_rect(Rect2(-64, -64, 344, 520), Palette.VOID)
	_draw_terrain(b)
	_draw_gems(b)
	_draw_mines(b)
	_draw_enemies(b)
	_draw_tele(b)
	_draw_player(b)
	_draw_bullets(b)
	_draw_fx(b)

func _draw_terrain(b: Battle) -> void:
	var s: WorldStrip = b.strip
	s.visible(_vis, -16.0, 400.0)
	for p in _vis:
		var oy: float = p.origin_y + s.scroll
		draw_rect(Rect2(WorldStrip.BORDER, oy, 192.0, p.height_px), Palette.T1)
		var w: int = p.def.width
		for r in p.def.height:
			var y: float = oy + r * 16.0
			if y > 392.0 or y + 16.0 < -8.0:
				continue
			for c in w:
				var bits: int = p.bits[r * w + c]
				if bits == 0:
					if (r + c) % 2 == 0:
						draw_rect(Rect2(WorldStrip.BORDER + c * 16.0, y, 16.0, 16.0), Palette.T2)
					continue
				var rect := Rect2(WorldStrip.BORDER + c * 16.0, y, 16.0, 16.0)
				if bits & ChunkDef.BIT_WALL:
					draw_rect(rect, Palette.T5)
					draw_rect(Rect2(rect.position, Vector2(16, 2)), Palette.T6)
				elif bits & ChunkDef.BIT_COVER:
					draw_rect(rect, Palette.COVER_M)
					draw_rect(rect.grow(-2.0), Palette.COVER_L)
				elif bits & ChunkDef.BIT_HAZARD:
					draw_rect(rect, Palette.HAZ_D)
					for k in 4:
						draw_line(rect.position + Vector2(k * 5.0 - 2.0, 16), rect.position + Vector2(k * 5.0 + 14.0, 0), Palette.HAZ_B, 1.0)
	draw_rect(Rect2(0, -64, WorldStrip.BORDER, 520), Palette.T3)
	draw_rect(Rect2(216.0 - WorldStrip.BORDER, -64, WorldStrip.BORDER, 520), Palette.T3)

func _draw_gems(b: Battle) -> void:
	for i in b.gn:
		var col: Color = Palette.XP if b.gv[i] < 3 else Palette.GOLD
		draw_rect(Rect2(b.gx[i] - 2.0, b.gy[i] - 2.0, 4.0, 4.0), col)

func _draw_mines(b: Battle) -> void:
	for i in b.mn:
		draw_circle(Vector2(b.mx[i], b.my[i]), 3.0, Palette.GOLD_S if b.ms[i] == 0 else Palette.DANGER)

func _draw_enemies(b: Battle) -> void:
	var e: EnemyPool = b.enemies
	for i in e.n:
		if e.hp[i] <= 0.0:
			continue
		var pos := Vector2(e.x[i], e.y[i])
		var r: float = e.rad[i]
		var fam: int = int(Defs.ENEMIES[EnemyPool.TYPE_IDS[e.type[i]]]["family"])
		var col: Color = Palette.ENM_A if fam == 0 else (Palette.ENM_B if fam == 1 else Palette.ELITE)
		if e.flash[i] > 0.0:
			col = Palette.WHITE
		if e.st[i] == EnemyPool.ST_EMERGE:
			draw_arc(pos, r, 0.0, TAU, 12, Palette.DANGER, 1.0)
			continue
		if e.type[i] == EnemyPool.T_BOSS:
			var bc: Color = Palette.WHITE if e.flash[i] > 0.0 else Palette.ELITE
			if e.st[i] == EnemyAI.BS_STUN:
				bc = Palette.GOLD
			draw_rect(Rect2(pos - Vector2(r, r), Vector2(r * 2.0, r * 2.0)), bc)
			draw_rect(Rect2(pos - Vector2(r - 3.0, r - 3.0), Vector2(r * 2.0 - 6.0, 4.0)), Palette.EYE)
			var f: float = clampf(e.hp[i] / e.maxhp[i], 0.0, 1.0)
			draw_rect(Rect2(pos.x - r, pos.y - r - 5.0, r * 2.0 * f, 3.0), Palette.DANGER)
			continue
		if fam == 0:
			draw_circle(pos, r, col)
			draw_rect(Rect2(pos.x - 1.0, pos.y - r - 1.0, 2.0, 2.0), Palette.OUTLINE)
		else:
			draw_rect(Rect2(pos - Vector2(r, r), Vector2(r * 2.0, r * 2.0)), col)
			draw_rect(Rect2(pos.x - 1.0, pos.y - 1.0, 2.0, 2.0), Palette.OUTLINE)
		if e.kind[i] == Defs.K_EXPLODER and e.st[i] == 1:
			draw_arc(pos, 36.0, 0.0, TAU, 20, Palette.DANGER, 1.0)
		if e.kind[i] == Defs.K_HEAVY and e.st[i] == 1:
			draw_arc(pos, 48.0, 0.0, TAU, 24, Palette.DANGER, 1.0)
		if e.type[i] == EnemyPool.T_EL:
			var fh: float = clampf(e.hp[i] / e.maxhp[i], 0.0, 1.0)
			draw_rect(Rect2(pos.x - r, pos.y - r - 4.0, r * 2.0 * fh, 2.0), Palette.DANGER)

func _draw_tele(b: Battle) -> void:
	if b.boss_tele_kind == 0:
		return
	var bi: int = b.enemies.index_of_uid(b.boss_uid)
	if bi < 0:
		return
	var by: float = b.enemies.y[bi]
	var a: float = 0.25 + 0.4 * b.boss_tele_t
	if b.boss_tele_kind == 1:
		draw_rect(Rect2(b.boss_tele_x - 16.0, by, 32.0, 400.0 - by), Color(Palette.DANGER, a))
	else:
		var d := Vector2(b.px - b.enemies.x[bi], b.py - by).normalized()
		draw_line(Vector2(b.enemies.x[bi], by), Vector2(b.enemies.x[bi], by) + d * 300.0, Color(Palette.DANGER, a), 1.0)

func _draw_player(b: Battle) -> void:
	var col: Color = Palette.SKIN_SWORD if b.class_id == &"sword" else Palette.SKIN_ARCH
	if b.invuln_left > 0.0 and int(b.invuln_left * 20.0) % 2 == 0:
		col = Palette.WHITE
	draw_circle(Vector2(b.px, b.py), b.bal.player_radius, col)
	draw_rect(Rect2(b.px - 1.0, b.py - 7.0, 2.0, 2.0), Palette.CORE)
	# 궤도 구체
	for k in b.orb_n:
		var a: float = b.orbit_angle + TAU * float(k) / float(b.orb_n)
		draw_circle(Vector2(b.px, b.py) + Vector2(cos(a), sin(a)) * b.orb_r, 4.0, Palette.CORE)
	if b.slow_on:
		draw_arc(Vector2(b.px, b.py), 9.0, 0.0, TAU, 16, Color(Palette.CORE, 0.4), 1.0)

func _draw_bullets(b: Battle) -> void:
	for i in b.abul.n:
		draw_rect(Rect2(b.abul.x[i] - 1.5, b.abul.y[i] - 1.5, 3.0, 3.0), Palette.ALLY_BUL)
	for i in b.ebul.n:
		draw_circle(Vector2(b.ebul.x[i], b.ebul.y[i]), 2.5, Palette.ENM_BUL_A)

func _draw_fx(b: Battle) -> void:
	for s in b.slashes:
		var f: float = float(s["life"]) / float(s["max"])
		var a0: float = float(s["ang"]) - float(s["arc"]) * 0.5
		draw_arc(Vector2(float(s["x"]), float(s["y"])), float(s["range"]) * 0.8, a0, a0 + float(s["arc"]), 16, Color(Palette.WHITE, f), 3.0)
	for m in b.booms:
		var f2: float = float(m["life"]) / float(m["max"])
		draw_arc(Vector2(float(m["x"]), float(m["y"])), float(m["r"]) * (1.2 - f2 * 0.2), 0.0, TAU, 24, Color(Palette.GOLD, f2), 2.0)
