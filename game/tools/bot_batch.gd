extends SceneTree
## T-18·T-19 봇 배치 집계. 측정만 하고 밸런스 값은 바꾸지 않는다(밸런스 변경은 사람 플레이 기록 후).
## 실행: godot --headless --path game --script res://tools/bot_batch.gd -- [--n=100] [--skill=0.85] [--out=<경로>]
## 단축판(early=true) 100판: 1판차 클리어율(AC-23), 평균 레벨업(AC-20), 사망 원인·구역 분포(AC-25).
## 3판 누적 클리어율: 시드 i, i+100, i+200 묶음 중 3판 안에 클리어가 1회 이상인 비율(AC-23).
## 정규판(early=false) 100판 평균 레벨업도 같이 낸다(AC-20 정규 10.5±1).

const STEP: float = 1.0 / 60.0
const MAX_STEPS: int = 60 * 400

func _init() -> void:
	var n: int = 100
	var skill: float = 0.85
	var out_path: String = "user://bot_batch.txt"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--n="):
			n = int(a.substr(4))
		elif a.begins_with("--skill="):
			skill = float(a.substr(8))
		elif a.begins_with("--out="):
			out_path = a.substr(6)
	var lines: PackedStringArray = []
	lines.append("bot batch n=%d skill=%.2f" % [n, skill])

	# 단축판 1판차 / 3판 묶음
	var early: Array = []
	for s in range(1, n + 1):
		early.append(_run(s, skill, true))
	var c1: int = 0
	var lv_sum: float = 0.0
	var lv_min: int = 1 << 30
	var causes: Dictionary = {}
	var zones: Dictionary = {}
	var kill_sum: float = 0.0
	var dur_sum: float = 0.0
	for r in early:
		if r["cleared"]:
			c1 += 1
		lv_sum += float(r["levelups"])
		lv_min = mini(lv_min, int(r["levelups"]))
		dur_sum += float(r["duration"])
		kill_sum += float(r["kills"])
		if not r["cleared"]:
			var cz: String = String(r["death_cause"]) if r["death_cause"] != &"" else "none"
			causes[cz] = int(causes.get(cz, 0)) + 1
			var zz: String = String(r["death_zone"])
			zones[zz] = int(zones.get(zz, 0)) + 1
	var bottom: int = int(causes.get("hazard", 0)) + int(causes.get("contact", 0))
	lines.append("[early] clear_rate_run1=%.3f (AC-23 50~70%%)" % (float(c1) / n))
	lines.append("[early] avg_levelups=%.2f min=%d (AC-20 5.5±1, min>=4)" % [lv_sum / n, lv_min])
	lines.append("[early] avg_duration_s=%.1f avg_kills=%.1f" % [dur_sum / n, kill_sum / n])
	lines.append("[early] death_causes=%s zones=%s" % [str(causes), str(zones)])
	var deaths: int = n - c1
	var floor_share: float = float(bottom) / float(maxi(deaths, 1))
	lines.append("[early] hazard+contact share of deaths=%.3f (AC-25 <0.30 관찰)" % floor_share)

	var groups_hit: int = 0
	var groups: int = mini(n, int(early.size() / 3))
	for i in range(groups):
		var hit: bool = false
		for k in 3:
			var idx: int = i + k * n
			if idx < early.size() and early[idx]["cleared"]:
				hit = true
		if hit:
			groups_hit += 1
	lines.append("[early] cumulative_3run_clear=%.3f (AC-23 >=0.80, 묶음 %d)" % [float(groups_hit) / maxf(groups, 1), groups])

	# 정규판 평균 레벨업 (AC-20)
	var reg_lv: float = 0.0
	var reg_clear: int = 0
	for s in range(1, n + 1):
		var r: Dictionary = _run(s, skill, false)
		reg_lv += float(r["levelups"])
		if r["cleared"]:
			reg_clear += 1
	lines.append("[normal] avg_levelups=%.2f clear_rate=%.3f (AC-20 10.5±1)" % [reg_lv / n, float(reg_clear) / n])

	var report: String = "\n".join(lines)
	print(report)
	var fa := FileAccess.open(out_path, FileAccess.WRITE)
	if fa != null:
		fa.store_string(report + "\n")
		fa.close()
		print("saved: %s" % ProjectSettings.globalize_path(out_path))
	quit(0)

func _run(seed_v: int, skill: float, early: bool) -> Dictionary:
	var b := Battle.new(Balance.new(), seed_v, &"sword", null, early)
	var bot := Bot.new(seed_v, skill)
	var box: Array = []
	b.run_ended.connect(func(r: Dictionary) -> void: box.append(r))
	var steps: int = 0
	while not b.ended and steps < MAX_STEPS:
		bot.drive(b)
		b.step(STEP)
		steps += 1
	if box.is_empty():
		# 시간 한도까지 끝나지 않으면 미완료로 집계한다
		return {"cleared": false, "levelups": b.levelups, "duration": b.run_time, "kills": b.kills,
			"death_cause": &"timeout", "death_zone": b.zone_name()}
	return box[0]
