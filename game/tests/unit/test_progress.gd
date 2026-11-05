extends TestCase
## T-04, T-05 (AC-19, AC-24) + 메타 노드

func test_t04_xp_curve() -> void:
	for n in range(1, 31):
		var expect: int = int(round(8.0 + 5.0 * n + 0.4 * n * n))   # 코어 함수와 독립 계산
		check_eq(XpCurve.need(n), expect, "xp_need(%d)" % n)
	check_eq(XpCurve.need(10), 98, "n=10")
	# QA 문서는 n=1 -> 14 라고 적었으나 공식(8+5+0.4=13.4)은 13 이다. 공식을 따른다.
	check_eq(XpCurve.need(1), 13, "n=1 (공식값)")

func test_early_run_first_need_is_8() -> void:
	var b := Battle.new(Balance.new(), 1, &"sword", null, true)
	check_eq(b.xp_need, 8, "판 1~3 xp_need(1)")
	var b2 := Battle.new(Balance.new(), 1, &"sword", null, false)
	check_eq(b2.xp_need, 13, "일반 판 xp_need(1)")

func test_t05_imprint_five_runs() -> void:
	var bal := Balance.new()
	var m := MetaState.new()
	# 1 A 사망, 2 C 사망(구역 A 내 사망 가정), 3 보스 첫 도달 사망, 4·5 클리어
	var scen: Array = [
		{"cleared": false, "boss_reached": false},
		{"cleared": false, "boss_reached": false},
		{"cleared": false, "boss_reached": true},
		{"cleared": true, "boss_reached": true},
		{"cleared": true, "boss_reached": true},
	]
	var grants: Array[int] = []
	for s in scen:
		grants.append(m.settle(s, bal))
	check_eq(str(grants), str([4, 4, 13, 18, 18] as Array[int]), "5판 지급")
	check_eq(Imprint.points(1, false, false) , 4, "P=8 실패 60%")
	check_eq(Imprint.points(1, false, true), 13, "P=23 실패 60%")
	check_eq(Imprint.points(1, true, false), 18, "P=18 클리어")
	check_eq(m.points, 57, "누적 지급 합(구매 없음)")

func test_forfeit_settles_as_fail() -> void:
	var bal := Balance.new()
	var m := MetaState.new()
	check_eq(m.settle({"cleared": false, "boss_reached": false}, bal), 4, "포기 60%")
	check_eq(m.settle({"cleared": false, "boss_reached": false, "forfeit": true}, bal), 4, "강제 종료 60%")

func test_node_purchase_flow() -> void:
	var m := MetaState.new()
	m.points = 4
	check(m.can_buy(&"n1"), "판 1 실패 지급 4 로 첫 노드 구매(비용 4)")
	check(m.buy(&"n1"), "buy n1")
	check_eq(m.points, 0, "잔액")
	check(not m.buy(&"n1"), "중복 구매 불가")
	check_near(m.stat(&"max_hp_mult"), 0.10, 0.0001, "효과 반영")
	var m2 := MetaState.from_dict(m.to_dict())
	check_eq(m2.owned.size(), 1, "직렬화 왕복")
	var b := Battle.new(Balance.new(), 1, &"sword", m)
	check_near(b.max_hp, 110.0, 0.01, "최대 체력 +10%")
