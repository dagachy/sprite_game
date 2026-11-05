extends TestCase
## C3 시드 프리셋 CAP-01~06 (user-acquisition-marketer §5): 목록, 오버라이드 적용, 결정성(수용 기준 1), CAP-04 정지 조건.

func _db() -> Dictionary:
	return ChunkDb.load_all()

func test_preset_list_has_six_ids() -> void:
	var ids: Array[StringName] = CapturePresets.ids()
	check_eq(ids.size(), 6, "six presets")
	check_eq(String(ids[0]), "CAP-01", "sorted first id")
	check_eq(String(ids[5]), "CAP-06", "sorted last id")

func test_god_override_applied_only_where_specified() -> void:
	var bal := Balance.load_default()
	var b1 := CapturePresets.make_battle(&"CAP-01", bal, _db(), MetaState.new())
	check(b1.god_mode, "CAP-01 god on")
	var b2 := CapturePresets.make_battle(&"CAP-02", bal, _db(), MetaState.new())
	# 입력 없이 무적 off 로 가면 t=23s 에 사망해 cover_01 도달 전에 끝난다(실측). 그래서 무적 on.
	check(b2.god_mode, "CAP-02 god on (idle 입력 기준 실측)")

func test_cap04_weapon_and_passive_applied() -> void:
	var bal := Balance.load_default()
	var b := CapturePresets.make_battle(&"CAP-04", bal, _db(), MetaState.new())
	check_eq(int(b.offer_state.weapons.get(&"W01", 0)), 4, "W01 lv4")
	check_eq(int(b.offer_state.passives.get(&"P01", 0)), 1, "P01 lv1")

func test_deterministic_digest_same_preset() -> void:
	var bal := Balance.load_default()
	var db := _db()
	var a := CapturePresets.make_battle(&"CAP-04", bal, db, MetaState.new())
	var na: int = CapturePresets.advance(a, &"CAP-04")
	var b := CapturePresets.make_battle(&"CAP-04", bal, db, MetaState.new())
	var nb: int = CapturePresets.advance(b, &"CAP-04")
	check_eq(na, nb, "same step count")
	check_eq(CapturePresets.state_digest(a), CapturePresets.state_digest(b), "digest equal")

func test_cap04_stops_at_offer_within_limit() -> void:
	var bal := Balance.load_default()
	var b := CapturePresets.make_battle(&"CAP-04", bal, _db(), MetaState.new())
	var n: int = CapturePresets.advance(b, &"CAP-04")
	# 정지 조건(3택 열림) 또는 상한 도달 중 하나. 열림이면 조기 정지이므로 상한보다 작거나 같다.
	check(n <= CapturePresets.MAX_STEPS, "within MAX_STEPS")
	check(b.awaiting_pick or n == CapturePresets.MAX_STEPS, "stopped at offer or limit")

func test_cap05_force_evolve_completes() -> void:
	var bal := Balance.load_default()
	var b := CapturePresets.make_battle(&"CAP-05", bal, _db(), MetaState.new())
	var n: int = CapturePresets.advance(b, &"CAP-05")
	check(n > 0, "steps advanced for evolve")
	check(b.evolve_queue.is_empty(), "evolve queue drained")
	check(b.offer_state.evolved.has(&"W01"), "W01 evolved")

func test_cap03_spawn_count_tops_up_to_12_on_screen() -> void:
	var b := CapturePresets.make_battle(&"CAP-03", Balance.load_default(), _db(), MetaState.new())
	CapturePresets.advance(b, &"CAP-03")
	# 보충만 하고 제거는 하지 않으므로 자연 스폰이 12 를 넘으면 그 수가 남는다(시드 12345 실측 15).
	check(CapturePresets._on_screen_count(b) >= 12, "at least 12 enemies on screen")

func test_chunk_sizes_give_same_digest_and_steps() -> void:
	var bal := Balance.load_default()
	var db := _db()
	var ref_digest: Dictionary = {}
	var ref_n: int = -1
	for chunk in [1, 400, 24000]:
		var b := CapturePresets.make_battle(&"CAP-06", bal, db, MetaState.new())
		var st: Dictionary = {}
		var calls: int = 0
		while not CapturePresets.advance_chunk(b, &"CAP-06", st, chunk):
			calls += 1
		var n: int = int(st["n"])
		if ref_n < 0:
			ref_n = n
			ref_digest = CapturePresets.state_digest(b)
		check_eq(n, ref_n, "step count chunk=%d" % chunk)
		check_eq(CapturePresets.state_digest(b), ref_digest, "digest chunk=%d" % chunk)

func test_cap03_same_seed_same_enemies() -> void:
	var bal := Balance.load_default()
	var db := _db()
	var a := CapturePresets.make_battle(&"CAP-03", bal, db, MetaState.new())
	CapturePresets.advance(a, &"CAP-03")
	var b := CapturePresets.make_battle(&"CAP-03", bal, db, MetaState.new())
	CapturePresets.advance(b, &"CAP-03")
	check_eq(a.enemies.n, b.enemies.n, "enemy count equal")
	check_eq(CapturePresets.state_digest(a), CapturePresets.state_digest(b), "digest equal")

## main.gd 는 프리프 종료 시 battle.current_offer/rerolls_left/offer_source 로 3택 박스를 다시 그린다. 그 읽기 접근이 유효한지 검사한다.
func test_cap04_stop_exposes_offer_for_deferred_ui() -> void:
	var bal := Balance.load_default()
	var b := CapturePresets.make_battle(&"CAP-04", bal, _db(), MetaState.new())
	var state: Dictionary = {}
	while not CapturePresets.advance_chunk(b, &"CAP-04", state, 30):
		pass
	check(b.awaiting_pick, "stops with offer open")
	check(b.current_offer.size() > 0, "current_offer readable")
	check(b.rerolls_left >= 0, "rerolls_left readable")

func test_skips_record_guard() -> void:
	check(not CapturePresets.skips_record(&"", false), "normal run records")
	check(CapturePresets.skips_record(&"CAP-01", false), "preset run skips record")
	check(CapturePresets.skips_record(&"", true), "debug-granted run skips record")
	check(CapturePresets.skips_record(&"CAP-01", true), "preset+granted skips record")
