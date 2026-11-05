class_name RunSettle extends RefCounted
## 판 종료 정산 + runs.jsonl 1줄 기록(노드 없음, 테스트 가능). main.gd 가 호출한다.
## 프리셋·부여 판(is_preset)은 메타·runs 를 건드리지 않고 0 을 돌려준다.
## 포기(quit_midrun)는 실패 결과(cleared=false)로 meta.settle 을 재사용하므로 imprint_fail_ratio(0.6)가 적용된다.
## runs.jsonl 의 result 는 기존 계약 값 "cleared"/"died" 만 쓴다(포기는 "died" + quit_midrun=true).
## 집계 규칙(E7): 사망률은 runs.jsonl 의 quit_midrun==false 줄만 센다. events 의 run_death 는 같은 run_id 가 quit_midrun==true 이거나 cause 가 비면 포기 후보로 제외한다.

static func finish(result: Dictionary, quit_midrun: bool, is_preset: bool, meta: MetaState,
		bal: Balance, logger: Object, run_id: String, debug: Dictionary) -> int:
	if is_preset:
		return 0
	var pts: int = meta.settle(result, bal)
	if logger != null:
		logger.run_record(build_record(result, quit_midrun, pts, run_id, debug))
	return pts

static func build_record(result: Dictionary, quit_midrun: bool, pts: int, run_id: String, debug: Dictionary) -> Dictionary:
	return {"run_id": run_id, "seed": int(result["seed"]), "class": String(result["class"]),
		"result": "cleared" if result["cleared"] else "died",
		"death_cause": String(result["death_cause"]), "death_zone": String(result["death_zone"]),
		"killer_kind": String(result["killer_kind"]),
		"duration_s": snappedf(float(result["duration"]), 0.01),
		"points": pts, "levelups": int(result["levelups"]), "kills": int(result["kills"]),
		"boss_reached": bool(result["boss_reached"]), "quit_midrun": quit_midrun,
		"retry_taps": null, "restart_latency_s": null,
		"pick_log": result["pick_log"].map(func(x: StringName) -> String: return String(x)),
		"debug": debug}
