extends TestCase
## P2 X2 / P3 Y: 디버그 API, 출처 키(killer_kind), 로그 봉투(P3 정본), BIT_EDGE 이동

func test_debug_set_weapon_and_passive() -> void:
	var b := Battle.new(Balance.new(), 5, &"sword", null, true)
	check(b.debug_set_weapon(&"W01", 3), "set weapon W01 lv3")
	check_eq(int(b.offer_state.weapons.get(&"W01", 0)), 3, "W01 level")
	check(b.weapon_order.has(&"W01"), "weapon order contains W01")
	check(b.debug_set_weapon(&"W01", 0), "remove weapon")
	check(not b.offer_state.weapons.has(&"W01"), "W01 removed")
	check(not b.debug_set_weapon(&"P01", 1), "passive id rejected by set_weapon")
	check(b.debug_give_passive(&"P01", 2), "give passive P01 x2")
	check_eq(int(b.offer_state.passives.get(&"P01", 0)), 2, "P01 level")
	check(not b.debug_give_passive(&"W01", 1), "weapon id rejected by give_passive")

func test_killer_kind_recorded() -> void:
	var b := Battle.new(Balance.new(), 6, &"sword", null, true)
	b.god_mode = false
	b.hurt(1.0, &"contact", false, true, &"boss")
	check_eq(String(b.last_killer_kind), "boss", "explicit killer kind")
	b.invuln_left = 0.0
	b.hurt(1.0, &"hazard", true, true)
	check_eq(String(b.last_killer_kind), "hazard", "killer kind falls back to cause")

func test_log_envelope_fields() -> void:
	var lg = load("res://scripts/core/log.gd").new()
	lg.enabled = true
	lg.dir_path = "user://test_logs_envelope"
	lg.run_id = "T-RUN"
	lg.event("unit_probe", {"t": 1.0})
	lg.event("unit_probe", {"t": 2.0})
	var fa := FileAccess.open("user://test_logs_envelope/events.jsonl", FileAccess.READ)
	var lines := fa.get_as_text().split("\n", false)
	fa.close()
	check_eq(lines.size(), 2, "two event lines")
	var js := JSON.new()
	js.parse(lines[1])
	var d: Dictionary = js.data
	check_eq(int(d["schema_ver"]), 1, "schema_ver")
	check_eq(int(d["seq"]), 1, "seq increments")
	check(d.has("t_ms") and d.has("ts"), "t_ms and ts present")
	check_eq(String(d["run_id"]), "T-RUN", "run_id")
	check_eq(String(d["ev"]), "unit_probe", "ev name")
	DirAccess.remove_absolute("user://test_logs_envelope/events.jsonl")
	lg.free()

func test_bit_edge_moved_off_gate_bit() -> void:
	check_eq(WorldStrip.BIT_EDGE, 128, "BIT_EDGE = 128 (P2 X2)")
	check_eq(WorldStrip.BIT_EDGE & (ChunkDef.BIT_WALL | ChunkDef.BIT_COVER | ChunkDef.BIT_HAZARD), 0, "no overlap with terrain bits")
