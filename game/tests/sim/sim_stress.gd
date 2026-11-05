extends TestCase
## 성능 스트레스(몹 150 + 탄 200, 고정 시드). 헤드리스 CPU 시간이라 기기 성능과 다르다 - 상대 비교용.
## 기준: 스텝당 평균 4ms 이하(60Hz 예산 16.6ms 중 시뮬 몫, 렌더 제외) [가정].

func test_stress_150_enemies_200_bullets() -> void:
	var bal := Balance.new()
	var b := Battle.new(bal, 99, &"archer", null, false)
	b.god_mode = true
	b.spawner.grace_until = 1e9
	b.set_input(true, Vector2(20.0, 0.0))
	b.offer_state.weapons[&"W01"] = 5
	b.offer_state.weapons[&"W03"] = 5
	b.offer_state.weapons[&"W04"] = 5
	b.weapon_order.append(&"W01")
	b.weapon_order.append(&"W03")
	b.weapon_order.append(&"W04")
	b.wcd[&"W03"] = 0.0
	b.wcd[&"W04"] = 0.0
	b.xp_need = 100000000
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var total_ms: float = 0.0
	var worst_ms: float = 0.0
	var steps: int = 600
	for s in steps:
		while b.enemies.alive_count() < bal.stress_alive:
			b.add_enemy(rng.randi_range(0, 3), rng.randf_range(20.0, 196.0), rng.randf_range(-20.0, 200.0))
		while b.ebul.n < 100:
			b.fire_enemy_bullet(rng.randf_range(20.0, 196.0), 0.0, 0.0, 1.0, 60.0, 6.0)
		while b.abul.n < 100:
			b.abul.add(rng.randf_range(20.0, 196.0), 380.0, 0.0, -60.0, 1.0, 5.0, 3, 0, 1)
		var t0: int = Time.get_ticks_usec()
		b.step(1.0 / 60.0)
		var ms: float = float(Time.get_ticks_usec() - t0) / 1000.0
		total_ms += ms
		worst_ms = maxf(worst_ms, ms)
	var avg: float = total_ms / float(steps)
	note("stress: avg %.2f ms/step, worst %.2f ms, enemies %d, bullets a%d e%d" % [avg, worst_ms, b.enemies.n, b.abul.n, b.ebul.n])
	check(avg < 4.0, "스텝 평균 %.2f ms" % avg)
