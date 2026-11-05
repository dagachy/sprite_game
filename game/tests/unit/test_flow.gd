extends TestCase
## 레벨업 흐름: 3택 중 월드 정지, 선택 후 재개, 플레이어 상태

func test_levelup_pauses_world_and_resumes() -> void:
	var b: Battle = TH.frozen_battle(2, &"sword", true)
	var offers: Array = []
	b.offer_ready.connect(func(c: Array, r: int, src: StringName) -> void: offers.append([c.size(), r, src]))
	b.xp = 8
	b.step(1.0 / 60.0)
	check(b.awaiting_pick, "레벨업 3택 대기")
	check_eq(b.level, 2, "레벨 2")
	check_eq(offers.size(), 1, "offer_ready 1회")
	check_eq(int(offers[0][0]), 3, "카드 3장")
	check_eq(int(offers[0][1]), 2, "무료 리롤 2")
	var t0: float = b.t
	run_for(b, 1.0)
	check_near(b.t, t0, 0.0001, "3택 중 월드 시간 정지")
	check(b.pick(0), "선택")
	check(not b.awaiting_pick, "재개")
	run_for(b, 0.5)
	check(b.t > t0 + 0.4, "월드 재개")

func test_multiple_levelups_chain() -> void:
	var b: Battle = TH.frozen_battle(2, &"sword", true)
	b.xp = 200
	b.step(1.0 / 60.0)
	check(b.pending_levels >= 1, "대기 레벨업 존재")
	var n: int = 0
	while b.awaiting_pick and n < 30:
		b.pick(0)
		n += 1
	check(n >= 2, "연속 3택 %d회" % n)
	check(not b.awaiting_pick, "모두 소진")

func test_death_ends_run_with_cause() -> void:
	var b: Battle = TH.frozen_battle()
	var box: Array = []
	b.run_ended.connect(func(r: Dictionary) -> void: box.append(r))
	b.hp = 1.0
	b.hurt(8.0, &"projectile")
	check_eq(box.size(), 1, "run_ended 1회")
	check_eq(str(box[0]["death_cause"]), "projectile", "사망 원인")
	check_eq(bool(box[0]["cleared"]), false, "실패")
	b.hurt(8.0, &"contact")
	check_eq(box.size(), 1, "종료 후 중복 없음")

func test_god_mode_blocks_damage() -> void:
	var b: Battle = TH.frozen_battle()
	b.god_mode = true
	b.hurt(50.0, &"contact")
	check_near(b.hp, 100.0, 0.001, "무적 토글")

func test_plaza_free_offer_and_exit() -> void:
	var b: Battle = TH.frozen_battle(4, &"sword", true)
	b.scroll_model.state = ScrollModel.S.PLAZA_DECEL
	b.scroll_model.timer = 99.0
	b.set_input(true, Vector2.ZERO)
	b.step(1.0 / 60.0)       # PLAZA_DECEL -> HOLD (콜백으로 3택 1회)
	check_eq(b.scroll_model.state, ScrollModel.S.PLAZA_HOLD, "광장 정지")
	check(b.awaiting_pick, "광장 3택")
	b.pick(0)
	check(b.plaza_exit_ready, "3택 후 출구 화살표")
