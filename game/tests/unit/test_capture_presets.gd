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
	check(not b2.god_mode, "CAP-02 god off")

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
