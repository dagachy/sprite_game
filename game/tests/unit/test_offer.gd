extends TestCase
## T-01 ~ T-03 (AC-14,15,16,17,18)

func _states() -> Array[OfferState]:
	var out: Array[OfferState] = []
	# 12 종 조합: 무기/패시브 보유 수, 레벨 분포, 슬롯 가득 여부
	var combos: Array = [
		[{&"W01": 1}, {}],
		[{&"W01": 3}, {&"P01": 1}],
		[{&"W01": 5}, {&"P02": 2}],
		[{&"W01": 4, &"W02": 1}, {&"P01": 1, &"P03": 2}],
		[{&"W01": 5, &"W02": 5, &"W03": 5, &"W04": 5}, {&"P01": 5, &"P02": 5, &"P03": 5, &"P04": 5}],
		[{&"W01": 2, &"W02": 2, &"W03": 2, &"W04": 2}, {&"P01": 1, &"P02": 1, &"P03": 1, &"P04": 1}],
		[{&"W01": 5, &"W02": 5, &"W03": 5, &"W04": 5}, {&"P01": 1, &"P02": 1, &"P03": 1}],
		[{&"W01": 5}, {&"P01": 5}],
		[{&"W01": 1, &"W02": 1, &"W03": 1}, {&"P01": 1, &"P02": 1}],
		[{&"W01": 1}, {&"P01": 5, &"P02": 5, &"P03": 5, &"P04": 5}],
		[{&"W02": 5}, {&"P03": 1}],
		[{&"W01": 4, &"W02": 4, &"W03": 4, &"W04": 4}, {&"P01": 4, &"P02": 4, &"P03": 4, &"P04": 4}],
	]
	for c in combos:
		var s := OfferState.new()
		for k in c[0].keys():
			s.weapons[k] = c[0][k]
		for k in c[1].keys():
			s.passives[k] = c[1][k]
		out.append(s)
	return out

func _ids(offer: Array[Dictionary]) -> Array:
	var r: Array = []
	for c in offer:
		r.append(c["id"])
	return r

func test_t01_offer_invariants_1000() -> void:
	var states: Array[OfferState] = _states()
	var bias: Dictionary = Defs.CLASSES[&"sword"]["bias"]
	var viol: int = 0
	for si in states.size():
		for sd in range(1, 1001):
			var st: OfferState = states[si].duplicate_state()
			var rng := RandomNumberGenerator.new()
			rng.seed = sd
			var offer: Array[Dictionary] = OfferGenerator.generate(st, bias, rng)
			var ids: Array = _ids(offer)
			var has_up: bool = false
			var has_up_cand: bool = false
			for id in st.weapons.keys():
				if int(st.weapons[id]) < Defs.MAX_LEVEL:
					has_up_cand = true
			for id in st.passives.keys():
				if int(st.passives[id]) < Defs.MAX_LEVEL:
					has_up_cand = true
			for c in offer:
				if c["kind"] != &"fallback" and not c["is_new"]:
					has_up = true
				if c["kind"] != &"fallback" and c["is_new"]:
					if (c["kind"] == &"weapon" and st.weapon_count() >= st.weapon_slots) or \
							(c["kind"] == &"passive" and st.passive_count() >= st.passive_slots):
						viol += 1
						check(false, "slot full but new card (state %d seed %d)" % [si, sd])
			if offer.size() != 3:
				check(false, "offer size %d (state %d seed %d)" % [offer.size(), si, sd])
			if has_up_cand and not has_up:
				check(false, "no upgrade card (state %d seed %d)" % [si, sd])
			for a in ids.size():
				for bb in range(a + 1, ids.size()):
					if ids[a] == ids[bb] and offer[a]["kind"] != &"fallback":
						check(false, "duplicate %s (state %d seed %d)" % [str(ids[a]), si, sd])
			# 리롤: 직전 3장 제외(후보가 충분하면)
			var ex: Array = ids.duplicate()
			var rng2 := RandomNumberGenerator.new()
			rng2.seed = sd + 7
			var re: Array[Dictionary] = OfferGenerator.generate(st, bias, rng2, ex)
			var cand_total: int = 0
			for id in Defs.BASE_WEAPONS:
				if st.weapons.has(id) and int(st.weapons[id]) < Defs.MAX_LEVEL: cand_total += 1
				elif not st.weapons.has(id) and st.weapon_count() < st.weapon_slots: cand_total += 1
			for id in Defs.BASE_PASSIVES:
				if st.passives.has(id) and int(st.passives[id]) < Defs.MAX_LEVEL: cand_total += 1
				elif not st.passives.has(id) and st.passive_count() < st.passive_slots: cand_total += 1
			if cand_total >= 6:
				for id in _ids(re):
					if ex.has(id) and not Defs.FALLBACKS.has(id):
						check(false, "reroll repeats %s (state %d seed %d)" % [str(id), si, sd])
	check(true, "ran")
	note("T-01: %d states x 1000 seeds" % states.size())

func test_t02_material_and_bias_stats() -> void:
	# 재료 패시브: W01 Lv(evolve_min) 보유 + P01 미보유 -> 3연속 레벨업 안에 P01 출현
	var bias: Dictionary = Defs.CLASSES[&"sword"]["bias"]
	var miss: int = 0
	for sd in range(1, 1001):
		var st := OfferState.new()
		st.weapons[&"W01"] = 4
		st.weapons[&"W02"] = 1
		st.passives[&"P03"] = 1
		var rng := RandomNumberGenerator.new()
		rng.seed = sd
		var seen: bool = false
		for k in 3:
			var offer: Array[Dictionary] = OfferGenerator.generate(st, bias, rng)
			OfferGenerator.commit(st, offer)
			for c in offer:
				if c["id"] == &"P01":
					seen = true
			if seen:
				break
		if not seen:
			miss += 1
	check_eq(miss, 0, "재료 패시브 3연속 안 출현 실패 횟수")
	# 검사 태그 가중: area/defense 항목이 기준선의 1.4~1.6배 (가중 1.5)
	var base_w: float = 0.0
	var st2 := OfferState.new()
	var w_area: float = OfferGenerator.weight(&"W03", true, st2, bias)    # area
	var w_plain: float = OfferGenerator.weight(&"W02", true, st2, {})     # 비편향
	check_near(w_area / st2.base_weight, 1.5, 0.1, "area 가중/기준")
	check_near(OfferGenerator.weight(&"P01", true, st2, bias) / st2.base_weight, 1.5, 0.1, "defense 가중/기준")
	base_w = w_plain
	check_near(base_w, st2.base_weight, 0.001, "비편향 가중 = 기준")

func test_t03_reroll_limit_and_reproducible() -> void:
	var seqs: Array = []
	for rep in 2:
		var b := Battle.new(Balance.new(), 77, &"sword", null, true)
		b.xp = 100
		b.set_input(true, Vector2.ZERO)
		b.step(1.0 / 60.0)
		check(b.awaiting_pick, "offer pending")
		var seq: Array = [_ids_of(b.current_offer)]
		check(b.reroll(), "reroll 1")
		seq.append(_ids_of(b.current_offer))
		check(b.reroll(), "reroll 2")
		seq.append(_ids_of(b.current_offer))
		check(not b.reroll(), "reroll 3 rejected")
		check_eq(b.rerolls_left, 0, "rerolls_left")
		seqs.append(seq)
	check_eq(str(seqs[0]), str(seqs[1]), "같은 시드 같은 리롤 결과")

func _ids_of(offer: Array[Dictionary]) -> Array:
	var r: Array = []
	for c in offer:
		r.append(str(c["id"]))
	return r
