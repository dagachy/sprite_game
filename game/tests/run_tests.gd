extends SceneTree
## 헤드리스 테스트 러너. 종료 코드 0 통과, 1 실패, 2 러너 오류.
## 실행: godot --headless --path game --script res://tests/run_tests.gd [-- --suite=<이름> --seed=<n>]
## 리포트: 실패 시 user://test_report.txt 에 기록한다.

const DIRS: Array[String] = ["res://tests/unit", "res://tests/sim"]

func _init() -> void:
	var suite_filter: String = ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--suite="):
			suite_filter = a.substr(8)
	var total_fail: int = 0
	var total_checks: int = 0
	var report: Array[String] = []
	var ran: int = 0
	for d in DIRS:
		var da := DirAccess.open(d)
		if da == null:
			printerr("RUNNER ERROR: cannot open %s" % d)
			quit(2)
			return
		var files: PackedStringArray = da.get_files()
		files.sort()
		for f in files:
			if not f.ends_with(".gd") or not (f.begins_with("test_") or f.begins_with("sim_")):
				continue
			if suite_filter != "" and not f.contains(suite_filter):
				continue
			var scr: GDScript = load(d.path_join(f)) as GDScript
			if scr == null or not scr.can_instantiate():
				printerr("RUNNER ERROR: cannot load %s" % f)
				quit(2)
				return
			var inst: Object = scr.new()
			if not (inst is TestCase):
				printerr("RUNNER ERROR: %s is not a TestCase" % f)
				quit(2)
				return
			var tc: TestCase = inst
			var methods: Array[String] = []
			for m in scr.get_script_method_list():
				if String(m["name"]).begins_with("test_"):
					methods.append(String(m["name"]))
			methods.sort()
			for m in methods:
				var before: int = tc.failures.size()
				var checks_before: int = tc.checks
				var t0: int = Time.get_ticks_msec()
				tc.call(m)
				# 검사 0건은 통과로 치지 않는다(스크립트 오류로 본문이 중단된 경우를 놓치지 않기 위함)
				if tc.checks == checks_before:
					tc.failures.append("no checks executed (script error or early exit?)")
				var ok: bool = tc.failures.size() == before
				ran += 1
				var line: String = "%s %s.%s (%d ms)" % ["PASS" if ok else "FAIL", f.get_basename(), m, Time.get_ticks_msec() - t0]
				print(line)
				if not ok:
					for k in range(before, tc.failures.size()):
						print("    - " + tc.failures[k])
						report.append("%s.%s: %s" % [f, m, tc.failures[k]])
			for n in tc.notes:
				print("    note: " + n)
			total_fail += tc.failures.size()
			total_checks += tc.checks
	print("== %d tests, %d checks, %d failures" % [ran, total_checks, total_fail])
	if ran == 0:
		printerr("RUNNER ERROR: no tests found")
		quit(2)
		return
	if total_fail > 0:
		var fa := FileAccess.open("user://test_report.txt", FileAccess.WRITE)
		if fa != null:
			fa.store_string("\n".join(report))
		quit(1)
		return
	quit(0)
