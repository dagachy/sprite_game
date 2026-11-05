extends TestCase

func _run(seed_v: int, skill: float, early: bool) -> Dictionary:
	var b := Battle.new(Balance.new(), seed_v, &"sword", null, early)
	var bot := Bot.new(seed_v, skill)
	var box: Array = []
	b.run_ended.connect(func(r: Dictionary) -> void: box.append(r))
	var steps: int = 0
	var peak: int = 0
	while not b.ended and steps < 60 * 400:
		bot.drive(b)
		b.step(1.0 / 60.0)
		peak = maxi(peak, b.enemies.n)
		steps += 1
	var result: Dictionary = box[0] if box.size() > 0 else {}
	result["steps"] = steps
	result["peak_alive"] = peak
	result["phase"] = b.phase
	result["dbg"] = "t=%.1f lvl=%d hp=%.0f dmg=%s ws=%.2f weapons=%s boss_st=%d" % [b.t, b.level, b.hp, str(b.dmg_by_src), b.clock.world_scale, str(b.offer_state.weapons), b.enemies.st[b.enemies.index_of_uid(b.boss_uid)] if b.enemies.index_of_uid(b.boss_uid) >= 0 else -1]
	result["boss_hp"] = b.enemies.hp[b.enemies.index_of_uid(b.boss_uid)] if b.enemies.index_of_uid(b.boss_uid) >= 0 else -1.0
	return result

func test_full_run_terminates_and_reports() -> void:
	for s in [1, 2, 3]:
		var r: Dictionary = _run(s, 0.85, false)
		check(r.has("cleared"), "seed %d run ended (steps %d, phase %d)" % [s, r["steps"], r["phase"]])
		note("seed %d cleared=%s level=%s kills=%s cause=%s zone=%s dur=%.1f peak=%d boss_hp=%s %s" % [s,
			str(r.get("cleared")), str(r.get("level")), str(r.get("kills")), str(r.get("death_cause")),
			str(r.get("death_zone")), float(r.get("duration", 0.0)), r["peak_alive"], str(r["boss_hp"]), r["dbg"]])
