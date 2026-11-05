extends TestCase
## T-10 ~ T-14 (+ AC-01, AC-02, AC-12)

func _count_hurts(b: Battle) -> Array:
	var box: Array = []
	b.player_hurt.connect(func(a: float, c: StringName) -> void: box.append([a, c]))
	return box

## 두 위험 바닥 셀(서로 60px 이상) 찾기. 같은 청크 안에서.
func _two_hazard_cells(b: Battle) -> Array[Vector3i]:
	var cells: Array[Vector3i] = TH.cells_with(b, ChunkDef.BIT_HAZARD)
	for a in cells:
		for c in cells:
			if a.x == c.x and absf(float(a.z - c.z)) * 16.0 > 64.0 and a.y == c.y:
				return [a, c]
	return []

func test_t10_hazard_ticks() -> void:
	var b: Battle = TH.frozen_battle()
	var cells: Array[Vector3i] = _two_hazard_cells(b)
	check_eq(cells.size(), 2, "위험 바닥 셀 쌍 발견")
	if cells.size() < 2:
		return
	var pc: Vector2 = TH.focus(b, cells[0])
	b.px = pc.x
	b.py = pc.y
	var ec: Vector2 = TH.focus(b, cells[0])   # scroll 동일
	var ex: float = 12.0 + cells[1].z * 16.0 + 8.0
	var box: Array = _count_hurts(b)
	b.god_mode = false
	b.invuln_left = 0.5          # 무적 중에도 틱이 들어가야 한다
	var i_el: int = b.add_enemy(EnemyPool.T_EL, ex, pc.y)
	var i_bs: int = b.add_enemy(EnemyPool.T_BOSS, ex, pc.y + 0.0, 0)
	var i_a: int = b.add_enemy(EnemyPool.T_A1, ex, pc.y)
	b.enemies.spd[i_el] = 0.0
	b.enemies.spd[i_a] = 0.0
	b.minion_t = 1e9
	var hp_el: float = b.enemies.hp[i_el]
	var hp_bs: float = b.enemies.hp[i_bs]
	b.invuln_left = 10.0
	run_for(b, 3.0)
	check_eq(box.size(), 6, "3.0s 위험 틱 횟수")
	check_near(b.hp, 100.0 - 6.0 * 2.5, 0.001, "플레이어 틱 6 x 2.5")
	check_near(b.invuln_left, 10.0 - 3.0, 0.05, "위험 바닥은 무적을 새로 만들지 않음(감소만)")
	var iel: int = b.enemies.index_of_uid(b.enemies.uid[i_el]) if i_el < b.enemies.n else -1
	# 정예: 6틱 x 2 = 12
	var el_idx: int = -1
	var bs_idx: int = -1
	for k in b.enemies.n:
		if b.enemies.type[k] == EnemyPool.T_EL: el_idx = k
		if b.enemies.type[k] == EnemyPool.T_BOSS: bs_idx = k
	check(el_idx >= 0, "정예 생존")
	if el_idx >= 0:
		check_near(hp_el - b.enemies.hp[el_idx], 12.0, 0.01, "정예 6틱 x 2")
	if bs_idx >= 0:
		check_near(b.enemies.hp[bs_idx], hp_bs, 0.001, "보스 위험 바닥 면역")
	var a_alive: bool = false
	for k in b.enemies.n:
		if b.enemies.type[k] == EnemyPool.T_A1:
			a_alive = true
	check(not a_alive, "무리 1(HP12)은 5/틱으로 3틱에 사망")

func test_t11_contact_invuln_window() -> void:
	for cls in [&"sword", &"archer"]:
		var b: Battle = TH.frozen_battle(1, cls)
		var box: Array = _count_hurts(b)
		for k in 5:
			var i: int = b.add_enemy(EnemyPool.T_A1, b.px + k, b.py)
			b.enemies.spd[i] = 0.0
		var window: float = 1.0 if cls == &"sword" else 0.8
		run_for(b, window - 0.05)
		check_eq(box.size(), 1, "%s 무적 창 안 피해 1회" % str(cls))
		run_for(b, 0.2)
		check_eq(box.size(), 2, "%s 무적 종료 후 다음 피해" % str(cls))

func test_t12_cover_blocks_enemy_not_ally() -> void:
	var b: Battle = TH.frozen_battle()
	var covers: Array[Vector3i] = TH.cells_with(b, ChunkDef.BIT_COVER)
	check(covers.size() > 0, "엄폐 셀 존재")
	if covers.is_empty():
		return
	var c: Vector2 = TH.focus(b, covers[0])
	b.px = 108.0
	b.py = 340.0
	# 적 탄: 엄폐 왼쪽에서 오른쪽으로
	b.ebul.add(c.x - 14.0, c.y, 80.0, 0.0, 6.0, 4.0)
	b.abul.add(c.x - 14.0, c.y, 80.0, 0.0, 6.0, 4.0, 0, 0, 1)
	b.step(0.1)
	check_eq(b.ebul.n, 0, "적 탄은 엄폐에서 차단")
	check_eq(b.abul.n, 1, "아군 탄은 엄폐 통과")
	# 벽은 둘 다 차단
	var walls: Array[Vector3i] = TH.cells_with(b, ChunkDef.BIT_WALL)
	for w in walls:
		if w.z > 0 and w.z < 11:
			var wc: Vector2 = TH.focus(b, w)
			b.abul.clear()
			b.abul.add(wc.x - 14.0, wc.y, 80.0, 0.0, 6.0, 4.0, 0, 0, 1)
			b.step(0.1)
			check_eq(b.abul.n, 0, "아군 탄은 벽에서 차단")
			break

func test_t13_evolution_and_wall_pierce() -> void:
	# 진화: W01 Lv4 + P01 보유(단축판 완화), 정예 처치 후 1.5s 뒤 교체
	var b: Battle = TH.frozen_battle()
	b.xp_need = 1000000   # 보석 획득으로 3택이 끼어들지 않게
	b.offer_state.weapons[&"W01"] = 4
	b.offer_state.passives[&"P01"] = 1
	b.px = 108.0
	b.py = 340.0
	b.strip.scroll = 0.0
	var i: int = b.add_enemy(EnemyPool.T_EL, 108.0, 320.0)
	b.enemies.spd[i] = 0.0
	b.damage_enemy(i, 99999.0, 0)
	check_eq(b.evolve_queue.size(), 1, "진화 예약")
	run_for(b, 1.4)
	check(not b.offer_state.evolved.has(&"W01"), "1.4s 에는 아직")
	run_for(b, 0.2)
	check(b.offer_state.evolved.has(&"W01"), "1.5s 뒤 진화")
	# 레벨 부족이면 예약 안 됨
	var b2: Battle = TH.frozen_battle()
	b2.offer_state.weapons[&"W01"] = 3
	b2.offer_state.passives[&"P01"] = 1
	var j: int = b2.add_enemy(EnemyPool.T_EL, 108.0, 320.0)
	b2.damage_enemy(j, 99999.0, 0)
	check_eq(b2.evolve_queue.size(), 0, "Lv3 은 진화 불가")
	# 원안(Lv5) 설정도 지원
	var bal5 := Balance.new()
	bal5.evolve_min_level = 5
	var b3 := Battle.new(bal5, 1)
	b3.offer_state.weapons[&"W01"] = 4
	b3.offer_state.passives[&"P01"] = 1
	var k3: int = b3.add_enemy(EnemyPool.T_EL, 108.0, 320.0)
	b3.damage_enemy(k3, 99999.0, 0)
	check_eq(b3.evolve_queue.size(), 0, "evolve_min_level=5 면 Lv4 불가")

func _wall_pair(b: Battle) -> Array:
	# 좌우가 바닥인 벽 셀 하나를 찾아 [플레이어 좌, 적 우] 화면 좌표 반환
	for w in TH.cells_with(b, ChunkDef.BIT_WALL):
		if w.z < 2 or w.z > 9 or w.y < 3 or w.y > 20:
			continue
		var c: Vector2 = TH.focus(b, w, 200.0)
		var l: int = TH.bits_at(b, c.x - 24.0, c.y)
		var m: int = TH.bits_at(b, c.x - 16.0, c.y)
		var r: int = TH.bits_at(b, c.x + 16.0, c.y)
		var r2: int = TH.bits_at(b, c.x + 24.0, c.y)
		if l == 0 and m == 0 and r == 0 and r2 == 0:
			return [Vector2(c.x - 20.0, c.y), Vector2(c.x + 20.0, c.y)]
	return []

func test_ac08_evolved_ignores_walls_basic_does_not() -> void:
	var b: Battle = TH.frozen_battle()
	var pair: Array = _wall_pair(b)
	check_eq(pair.size(), 2, "벽 셀 쌍 발견")
	if pair.size() < 2:
		return
	b.px = pair[0].x
	b.py = pair[0].y
	var i: int = b.add_enemy(EnemyPool.T_A1, pair[1].x, pair[1].y)
	b.enemies.spd[i] = 0.0
	b.enemies.hp[i] = 500.0
	var hp0: float = b.enemies.hp[i]
	run_for(b, 2.0)
	check_near(b.enemies.hp[b.enemies.index_of_uid(b.enemies.uid[0])] if b.enemies.n > 0 else 0.0, hp0, 0.001, "기본 W01 은 벽 뒤 적을 못 벰")
	b.offer_state.evolved[&"W01"] = true
	b.wcd[&"W01"] = 0.0
	run_for(b, 1.0)
	check(b.enemies.n > 0 and b.enemies.hp[0] < hp0, "진화형은 벽 너머 피해")

func test_t14_auto_aim_hold() -> void:
	var aim := AutoAim.new()
	var xs := PackedFloat32Array([100.0, 120.0, 140.0, 160.0, 180.0])
	var ys := PackedFloat32Array([200.0, 200.0, 200.0, 200.0, 200.0])
	var hp := PackedFloat32Array([10.0, 10.0, 10.0, 10.0, 10.0])
	var uids := PackedInt32Array([1, 2, 3, 4, 5])
	var idx: int = aim.update(0.0, 108.0, 296.0, xs, ys, hp, uids, 5, 300.0, -4.0)
	check_eq(uids[idx], 1, "가장 가까운 적(거리 차 기준)")
	# 거리 차 16px 이내로 다른 적이 더 가까워지면 유지
	xs[1] = 108.0
	ys[1] = 200.0
	xs[0] = 108.0 + 6.0
	idx = aim.update(0.6, 108.0, 296.0, xs, ys, hp, uids, 5, 300.0, -4.0)
	check_eq(uids[idx], 1, "차이 작으면 유지(홀드 만료 후에도)")
	# 16px 넘게 가까우면 홀드 만료 시 교체, 홀드 중에는 유지
	var aim2 := AutoAim.new()
	xs = PackedFloat32Array([100.0, 160.0, 200.0, 150.0, 90.0])
	ys = PackedFloat32Array([150.0, 200.0, 250.0, 100.0, 50.0])
	idx = aim2.update(0.0, 108.0, 296.0, xs, ys, hp, uids, 5, 400.0, -4.0)
	var first_uid: int = uids[idx]
	ys[3] = 280.0
	xs[3] = 108.0                     # uid 4 가 훨씬 가까움
	idx = aim2.update(0.1, 108.0, 296.0, xs, ys, hp, uids, 5, 400.0, -4.0)
	check_eq(uids[idx], first_uid, "홀드 0.5s 중에는 유지")
	idx = aim2.update(0.5, 108.0, 296.0, xs, ys, hp, uids, 5, 400.0, -4.0)
	check_eq(uids[idx], 4, "홀드 만료 후 교체")

func test_ac01_movement_responds_in_two_frames() -> void:
	var b: Battle = TH.frozen_battle()
	b.set_input(false, Vector2.ZERO)
	b.step(1.0 / 60.0)
	var x0: float = b.px
	b.set_input(true, Vector2.ZERO)
	b.step(1.0 / 60.0)
	b.set_input(true, Vector2(12.0, 0.0))
	b.step(1.0 / 60.0)
	b.step(1.0 / 60.0)
	check(b.px - x0 > 0.2, "터치 후 2프레임 내 이동 (dx=%.3f)" % (b.px - x0))
	# 같은 논리 드래그 거리는 같은 이동량(해상도 무관: 입력은 논리 좌표로 받는다)
	var b2: Battle = TH.frozen_battle()
	var b3: Battle = TH.frozen_battle()
	for bb in [b2, b3]:
		bb.set_input(true, Vector2(30.0, 0.0))
		run_for(bb, 1.0)
	check_near(b2.px, b3.px, 0.001, "같은 입력 -> 같은 위치")

func test_ac02_slow_converges() -> void:
	var b: Battle = TH.frozen_battle()
	b.set_input(false, Vector2.ZERO)
	run_for(b, 0.1)
	check_near(b.clock.world_scale, 0.5, 0.02, "손 뗀 뒤 world_scale 0.5")
	b.set_input(true, Vector2.ZERO)
	run_for(b, 0.1)
	check_near(b.clock.world_scale, 1.0, 0.02, "다시 1.0")

func test_ac12_shake_off_means_zero_offset() -> void:
	var bal := Balance.new()
	bal.shake_enabled = false
	var b := Battle.new(bal, 1)
	b.hurt(5.0, &"contact")
	check_near(b.shake_left, 0.0, 0.0001, "흔들림 off 시 요청 없음")
	var b2 := Battle.new(Balance.new(), 1)
	b2.hurt(5.0, &"contact")
	check(b2.shake_left > 0.0, "흔들림 on 이면 요청")

func test_boss_flow_and_stun() -> void:
	var b: Battle = TH.frozen_battle(3)
	# 아레나를 목표 위치까지 직접 스크롤
	b.strip.scroll = bal_arena_scroll(b)
	b._start_boss()
	check_eq(b.phase, Battle.Phase.BOSS, "보스 단계")
	b.god_mode = true
	var bi: int = b.enemies.index_of_uid(b.boss_uid)
	check(bi >= 0, "보스 생성")
	check_near(b.enemies.hp[bi], 2000.0, 0.01, "보스 HP")
	# 인트로 무적
	b.damage_enemy(bi, 100.0, 0)
	check_near(b.enemies.hp[bi], 2000.0, 0.01, "인트로 중 무적")
	# 기둥 아래(col 3, 기둥 row 8~9) 에 서면 돌진이 기둥에 막혀 스턴
	b.px = 12.0 + 3.0 * 16.0 + 8.0
	b.py = b.strip.arena.origin_y + b.strip.scroll + 12.0 * 16.0
	run_for(b, 6.0)
	check(b.pillar_stuns >= 1, "기둥 스턴 발생 (pillar_stuns=%d)" % b.pillar_stuns)

func bal_arena_scroll(b: Battle) -> float:
	return b.bal.arena_top_y - b.strip.arena.origin_y
