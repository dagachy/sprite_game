class_name OfferGenerator extends RefCounted
## 레벨업 3택 (mechanics §6.2). 노드 비의존 순수 클래스. 시드 고정 RNG 를 받는다.
## 카드: {kind: &"weapon"/&"passive"/&"fallback", id, is_new, level(선택 후 레벨), key}
## generate() 는 state 를 바꾸지 않는다. 3택이 확정되면 commit() 을 한 번 호출한다(리롤 시 중복 카운트 방지).

static func generate(state: OfferState, bias: Dictionary, rng: RandomNumberGenerator,
		exclude: Array = []) -> Array[Dictionary]:
	var upgrades: Array[StringName] = []
	var news: Array[StringName] = []
	for id in state.weapons.keys():
		if state.evolved.has(id):
			continue
		if int(state.weapons[id]) < Defs.MAX_LEVEL:
			upgrades.append(id)
	for id in state.passives.keys():
		if int(state.passives[id]) < Defs.MAX_LEVEL:
			upgrades.append(id)
	if state.weapon_count() < state.weapon_slots:
		for id in Defs.BASE_WEAPONS:
			if not state.weapons.has(id):
				news.append(id)
	if state.passive_count() < state.passive_slots:
		for id in Defs.BASE_PASSIVES:
			if not state.passives.has(id):
				news.append(id)

	var up_pool := _filter_excluded(upgrades, exclude)
	var new_pool := _filter_excluded(news, exclude)
	# 리롤 제외로 비면 제외를 해제한다
	var total_free := upgrades.size() + news.size()
	if up_pool.size() + new_pool.size() < mini(3, total_free):
		up_pool = upgrades.duplicate()
		new_pool = news.duplicate()

	var out: Array[Dictionary] = []
	var picked: Array[StringName] = []
	# 1) 강화 1 보장
	if up_pool.size() > 0:
		var id := _pick(up_pool, state, bias, rng)
		picked.append(id)
		out.append(_card(id, false, state))
	# 2) 신규 1
	var new_left := _without(new_pool, picked)
	if new_left.size() > 0:
		var id := _pick(new_left, state, bias, rng)
		picked.append(id)
		out.append(_card(id, true, state))
	# 3) 무작위 1 (합집합에서 중복 제외)
	var rest: Array[StringName] = []
	for id in up_pool:
		if not picked.has(id):
			rest.append(id)
	for id in new_pool:
		if not picked.has(id):
			rest.append(id)
	if rest.size() > 0:
		var id := _pick(rest, state, bias, rng)
		picked.append(id)
		out.append(_card(id, not state.owns(id), state))
	# 4) 부족하면 폴백 카드
	var fb_used: Array[StringName] = []
	while out.size() < 3:
		var fid := _fallback(state, fb_used, rng)
		fb_used.append(fid)
		out.append({"kind": &"fallback", "id": fid, "is_new": false, "level": 0, "key": Defs.item_key(fid)})
	return out

## 확정된 3택을 반영: 재료 패시브 연속 미출현 카운터 갱신
static func commit(state: OfferState, offer: Array[Dictionary]) -> void:
	var has_material_candidate := false
	for id in Defs.BASE_PASSIVES:
		if is_material(id, state):
			has_material_candidate = true
	var shown := false
	for c in offer:
		if c["kind"] == &"passive" and is_material(c["id"], state):
			shown = true
		if c["kind"] == &"fallback":
			state.last_fallback = c["id"]
	if shown or not has_material_candidate:
		state.since_material = 0
	else:
		state.since_material += 1

## 무기 Lv5(미진화) 이고 그 진화 재료 패시브를 아직 안 가진 경우의 패시브
static func is_material(id: StringName, state: OfferState) -> bool:
	if not Defs.is_passive(id) or state.passives.has(id):
		return false
	for wid in state.weapons.keys():
		if state.evolved.has(wid) or int(state.weapons[wid]) < Defs.MAX_LEVEL:
			continue
		if Defs.EVOLUTIONS.has(wid) and Defs.EVOLUTIONS[wid]["passive"] == id:
			return true
	return false

static func weight(id: StringName, is_new: bool, state: OfferState, bias: Dictionary) -> float:
	var w := state.base_weight
	for t in Defs.item_tags(id):
		w *= float(bias.get(t, 1.0))
		w *= float(state.tag_bias.get(t, 1.0))
	if is_material(id, state):
		w *= state.material_boost
		if state.since_material >= state.material_pity - 1:
			return INF
	return w

static func _pick(pool: Array[StringName], state: OfferState, bias: Dictionary,
		rng: RandomNumberGenerator) -> StringName:
	var ws: Array[float] = []
	var total := 0.0
	var inf_ids: Array[StringName] = []
	for id in pool:
		var w := weight(id, not state.owns(id), state, bias)
		if is_inf(w):
			inf_ids.append(id)
		ws.append(w)
		total += w
	if inf_ids.size() > 0:
		return inf_ids[rng.randi_range(0, inf_ids.size() - 1)]
	var r := rng.randf() * total
	for i in pool.size():
		r -= ws[i]
		if r <= 0.0:
			return pool[i]
	return pool[pool.size() - 1]

static func _card(id: StringName, is_new: bool, state: OfferState) -> Dictionary:
	var kind: StringName = &"weapon" if Defs.is_weapon(id) else &"passive"
	return {"kind": kind, "id": id, "is_new": is_new, "level": state.level_of(id) + 1, "key": Defs.item_key(id)}

static func _filter_excluded(src: Array[StringName], exclude: Array) -> Array[StringName]:
	var out: Array[StringName] = []
	for id in src:
		if not exclude.has(id):
			out.append(id)
	return out

static func _without(src: Array[StringName], picked: Array[StringName]) -> Array[StringName]:
	var out: Array[StringName] = []
	for id in src:
		if not picked.has(id):
			out.append(id)
	return out

static func _fallback(state: OfferState, used: Array[StringName], rng: RandomNumberGenerator) -> StringName:
	var cands: Array[StringName] = []
	for f in Defs.FALLBACKS:
		if not used.has(f) and f != state.last_fallback:
			cands.append(f)
	if cands.is_empty():
		for f in Defs.FALLBACKS:
			if not used.has(f):
				cands.append(f)
	return cands[rng.randi_range(0, cands.size() - 1)]
