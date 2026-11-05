extends TestCase
## T-09 스폰 규칙 / T-07 시드 결정성 (AC-28, AC-29, AC-27, AC-48)

func _run_zone(seed_v: int) -> Battle:
	var b := Battle.new(Balance.new(), seed_v, &"sword", null, false)
	b.god_mode = true
	b.spawn_log_enabled = true
	var bot := Bot.new(seed_v, 0.85)
	var steps: int = 0
	while b.phase == Battle.Phase.ZONE and not b.ended and steps < 60 * 220:
		bot.drive(b)
		b.step(1.0 / 60.0)
		steps += 1
	return b

func test_t09_spawn_rules_five_seeds() -> void:
	for sd in [1, 2, 3, 4, 5]:
		var b: Battle = _run_zone(sd)
		check(b.spawn_log.size() > 20, "seed %d 스폰 로그 %d건" % [sd, b.spawn_log.size()])
		var bad_bits: int = 0
		var bad_y: int = 0
		var bad_near: int = 0
		for s in b.spawn_log:
			# 링 스폰 위치는 스폰 시점 기준 벽/엄폐/위험 위가 아니어야 한다
			if int(s["bits"]) & (ChunkDef.BIT_WALL | ChunkDef.BIT_COVER | ChunkDef.BIT_HAZARD):
				if s["source"] != &"marker":
					bad_bits += 1
			if float(s["y"]) >= 288.0:
				bad_y += 1
			if s["source"] != &"marker" and Vector2(float(s["x"]) - float(s["px"]), float(s["y"]) - float(s["py"])).length() < 96.0:
				bad_near += 1
		check_eq(bad_bits, 0, "seed %d 벽/엄폐/위험 위 링 스폰" % sd)
		check_eq(bad_y, 0, "seed %d y>=288 스폰" % sd)
		check_eq(bad_near, 0, "seed %d 플레이어 96px 이내 링 스폰" % sd)
		# S 마커 그룹 발생률
		var total: int = 0
		var fired: int = 0
		for p in b.strip.placed:
			if p.slot < 0 or p.slot > 5:
				continue
			for m in p.markers:
				if m["ch"] == "S":
					# 시작 시점에 이미 y>128 인 슬롯 0 마커는 규칙상 도달 불가(창 [-32,128] 하향 통과) -> 분모 제외
					if p.slot == 0 and float(m["wy"]) > 128.0:
						continue
					total += 1
					if m["fired"]:
						fired += 1
		var rate: float = float(fired) / maxf(float(total), 1.0)
		check(rate >= 0.95, "seed %d S 마커 발생률 %.2f (%d/%d)" % [sd, rate, fired, total])
		note("seed %d spawns=%d markers %d/%d peak_alive<=36 end t=%.1f" % [sd, b.spawn_log.size(), fired, total, b.t])

func test_first_spawn_grace_3s() -> void:
	var b := Battle.new(Balance.new(), 9, &"sword", null, true)
	b.spawn_log_enabled = true
	b.set_input(true, Vector2.ZERO)
	run_for(b, 2.9)
	check_eq(b.spawn_log.size(), 0, "3초 전 스폰 없음")
	run_for(b, 1.0)
	check(b.spawn_log.size() > 0, "3초 직후 스폰 시작")
	if b.spawn_log.size() > 0:
		check_near(float(b.spawn_log[0]["t"]), 3.0, 0.1, "첫 스폰 시각")
		check(b.spawn_log[0]["source"] == &"marker", "첫 스폰은 슬롯 0 의 S 마커")
		check_near(float(b.spawn_log[0]["y"]), 60.0, 40.0, "첫 그룹 y 근처 60")

func test_t07_same_seed_same_world() -> void:
	for sd in [11, 22, 33, 44, 55]:
		var a: Battle = _run_for_log(sd, false)
		var c: Battle = _run_for_log(sd, false)
		check_eq(str(a.chain), str(c.chain), "seed %d 청크 순서" % sd)
		check_eq(str(a.spawn_log), str(c.spawn_log), "seed %d 스폰 열" % sd)
		check_near(a.strip.scroll, c.strip.scroll, 0.001, "seed %d 스크롤 오프셋" % sd)

func _run_for_log(sd: int, early: bool) -> Battle:
	var b := Battle.new(Balance.new(), sd, &"sword", null, early)
	b.god_mode = true
	b.spawn_log_enabled = true
	var bot := Bot.new(sd, 0.85)
	for i in 60 * 40:
		bot.drive(b)
		b.step(1.0 / 60.0)
	return b

func test_t07_spawn_rng_isolated_from_offer_rng() -> void:
	var a := Battle.new(Balance.new(), 5)
	var c := Battle.new(Balance.new(), 5)
	for i in 500:
		c.rng_offer.randf()      # 3택/리롤이 RNG 를 얼마나 쓰든
	var seq_a: Array = []
	var seq_c: Array = []
	for i in 30:
		seq_a.append(a.spawner.pick_kind())
		seq_c.append(c.spawner.pick_kind())
	check_eq(str(seq_a), str(seq_c), "스폰 열 불변")
