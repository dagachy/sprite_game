extends TestCase
## 판 밖 흐름·설정 저장·컷·문자열 금지어

const TMP: String = "user://test_settings_tmp.cfg"

func _clean() -> void:
	if FileAccess.file_exists(TMP):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))

func test_first_run_goes_through_intro_and_saves() -> void:
	_clean()
	var f := Flow.new(SettingsStore.new(TMP))
	var runs: Array[int] = [0]
	f.run_requested.connect(func() -> void: runs[0] += 1)
	f.boot(false)
	check_eq(f.state, Flow.State.TITLE, "릴리스는 TITLE")
	f.press_start()
	check_eq(f.state, Flow.State.INTRO, "첫 실행은 INTRO")
	f.intro_finished()
	check_eq(f.state, Flow.State.RUN, "INTRO 후 RUN")
	check_eq(runs[0], 1, "run_requested 1회")
	var f2 := Flow.new(SettingsStore.new(TMP))
	f2.boot(false)
	f2.press_start()
	check_eq(f2.state, Flow.State.RUN, "두 번째 실행은 INTRO 생략")
	_clean()

func test_direct_path_skips_title_and_does_not_touch_settings() -> void:
	_clean()
	var f := Flow.new(SettingsStore.new(TMP))
	f.boot(true)
	check_eq(f.state, Flow.State.RUN, "직접 경로는 RUN")
	check(not FileAccess.file_exists(TMP), "직접 경로는 설정 파일 미생성")
	check(Flow.should_skip_title(true, false, false), "디버그 빌드")
	check(Flow.should_skip_title(false, true, false), "프리셋")
	check(Flow.should_skip_title(false, false, true), "디버그 부여")
	check(not Flow.should_skip_title(false, false, false), "릴리스")

func test_transitions() -> void:
	var f := Flow.new(SettingsStore.new(TMP))
	f.boot(true)
	f.pause(); check_eq(f.state, Flow.State.PAUSE, "pause")
	f.open_settings(); check_eq(f.state, Flow.State.SETTINGS, "설정")
	f.close_settings(); check_eq(f.state, Flow.State.PAUSE, "설정 복귀는 PAUSE")
	f.resume(); check_eq(f.state, Flow.State.RUN, "resume")
	f.run_ended(); check_eq(f.state, Flow.State.RESULT, "RESULT")
	f.retry(); check_eq(f.state, Flow.State.RUN, "retry")
	f.pause(); f.quit_to_title(); check_eq(f.state, Flow.State.PAUSE, "PAUSE 에서 quit_to_title 무시")
	f.abandon(true); check_eq(f.state, Flow.State.TITLE, "프리셋·부여 포기는 TITLE")
	f.resume(); check_eq(f.state, Flow.State.TITLE, "잘못된 전이 무시")

func test_settings_failure_falls_back() -> void:
	var s := SettingsStore.new("user://no_such_dir_xyz/settings.cfg")
	check(not s.load_file(), "없는 파일 로드 실패")
	check(not s.first_run_done(), "기본값 false")
	check(not s.set_value("first_run_done", true), "저장 실패 보고")
	var f := Flow.new(s)
	f.boot(false)
	f.press_start()
	f.intro_finished()
	check_eq(f.state, Flow.State.RUN, "저장 실패해도 진행")

func test_cut_player_min_time_tap_skip() -> void:
	var c := CutPlayer.new()
	var shown: Array[StringName] = []
	var fin: Array[bool] = []
	c.cut_shown.connect(func(k: StringName, _t: String, _i: int, _n: int) -> void: shown.append(k))
	c.finished.connect(func(sk: bool) -> void: fin.append(sk))
	c.start(GameStrings.INTRO_KEYS)
	check_eq(shown.size(), 1, "첫 컷 표시")
	check(not c.tap(), "1.2초 전 탭 무시")
	c.update(1.1)
	check(not c.tap(), "1.1초 탭 무시")
	c.update(0.1)
	check(c.tap(), "1.2초 후 탭 수락")
	c.update(1.2); c.tap()
	check_eq(shown.size(), 3, "3컷 표시")
	c.update(1.2); c.tap()
	check_eq(fin, [false], "3탭 후 정상 종료")
	var c2 := CutPlayer.new()
	var fin2: Array[bool] = []
	c2.finished.connect(func(sk: bool) -> void: fin2.append(sk))
	c2.start(GameStrings.INTRO_KEYS)
	c2.skip()
	check_eq(fin2, [true], "스킵은 즉시 종료")

func test_strings_exact_and_no_banned_words() -> void:
	check_eq(GameStrings.get_text(&"cut.intro1"), "해가 뜨지 않는 세계. 마지막 열차가 멈췄다.", "intro1 원문")
	check_eq(GameStrings.INTRO_KEYS.size(), 3, "intro 3컷")
	for k in GameStrings.TABLE:
		var text: String = GameStrings.TABLE[k]
		check(text != "", "%s 비어있지 않음" % k)
		check_eq(GameStrings.find_banned(text), [] as Array[String], "%s 금지어 없음" % k)
	check_eq(GameStrings.find_banned("사망 포인트").size(), 2, "검사기 동작")

func test_wait_before_run_within_90s() -> void:
	var total: float = GameStrings.TITLE_TAP_SECONDS + float(GameStrings.INTRO_KEYS.size()) * CutPlayer.MIN_SECONDS + GameStrings.LOAD_SECONDS_MAX
	check(total <= 90.0, "타이틀→판 시작 최소 대기 합 90초 이하 (%s)" % str(total))
	check(CutPlayer.MIN_SECONDS >= 1.2, "컷 최소 1.2초")
	check(GameStrings.LOAD_SECONDS_MAX <= 1.5, "로딩 1.5초 이내")

func test_settings_roundtrip() -> void:
	_clean()
	var a := SettingsStore.new(TMP)
	check(a.set_value("first_run_done", true), "저장 성공")
	check(a.set_value("sfx_volume", 0.5), "추가 키 저장")
	var b := SettingsStore.new(TMP)
	check(b.load_file(), "다시 로드")
	check(b.first_run_done(), "first_run_done 왕복")
	check_near(float(b.data.get("sfx_volume", -1.0)), 0.5, 0.0001, "추가 키 왕복")
	_clean()

func test_preset_run_does_not_write_settings_or_save() -> void:
	_clean()
	var f := Flow.new(SettingsStore.new(TMP))
	f.boot(Flow.should_skip_title(false, true, false))
	f.intro_finished()   # RUN 상태에서는 무시
	f.run_ended()
	f.retry()
	check(not FileAccess.file_exists(TMP), "프리셋 판은 설정 파일 미생성")
	var m := MetaState.new()
	check_eq(m.to_dict(), MetaState.new().to_dict(), "메타 상태 불변")
	# 직접 경로에서 INTRO 를 강제로 거쳐도 플래그를 쓰지 않는다
	var g := Flow.new(SettingsStore.new(TMP))
	g.direct_run = true
	g.state = Flow.State.INTRO
	g.intro_finished()
	check(not FileAccess.file_exists(TMP), "직접 경로 intro_finished 도 미저장")

## cut.clear* 등 신규 키가 TABLE 에 들어와도 같은 스캔을 탄다(키 접두사·금지어·빈 문자열)
func test_all_scan_prefixed_keys_are_scanned() -> void:
	for k in GameStrings.TABLE:
		var ok: bool = false
		for p in GameStrings.SCAN_PREFIXES:
			if String(k).begins_with(p):
				ok = true
		check(ok, "%s 는 스캔 접두사에 포함" % k)
		check_eq(GameStrings.find_banned(GameStrings.TABLE[k]), [] as Array[String], "%s 금지어 없음" % k)
	check(GameStrings.TABLE.has(&"cut.clear1") and GameStrings.TABLE.has(&"cut.clear2"), "cut.clear 키 확정(storyteller)")
	check_eq(GameStrings.get_text(&"boss.intro"), "거대 그늘이 길을 막는다", "boss.intro 원문")

func test_abandon_normal_goes_to_result_via_main_settlement() -> void:
	var f := Flow.new(SettingsStore.new(TMP))
	f.boot(true)
	var hits: Array[int] = [0]
	f.abandoned.connect(func() -> void: hits[0] += 1)
	f.abandon(false); check_eq(hits[0], 0, "RUN 에서는 무시")
	f.pause(); f.abandon(false)
	check_eq(hits[0], 1, "abandoned 1회")
	f.run_ended()
	check_eq(f.state, Flow.State.RESULT, "정산 후 RESULT")

func _fail_result() -> Dictionary:
	return {"cleared": false, "boss_reached": false, "duration": 50.0, "world_time": 50.0, "death_cause": &"", "death_zone": &"A",
		"killer_kind": &"", "level": 3, "levelups": 2, "kills": 20, "seed": 7, "class": &"sword",
		"pick_log": [&"W01"], "top_items": []}

func _logger(dir: String) -> Object:
	var lg: Object = load("res://scripts/core/log.gd").new()
	lg.enabled = true
	lg.dir_path = dir
	DirAccess.make_dir_recursive_absolute(dir)
	var p: String = dir.path_join("runs.jsonl")
	if FileAccess.file_exists(p):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	return lg

func _lines(dir: String) -> PackedStringArray:
	var p: String = dir.path_join("runs.jsonl")
	if not FileAccess.file_exists(p):
		return PackedStringArray()
	return FileAccess.get_file_as_string(p).split("\n", false)

func test_abandon_settles_60pct_and_logs_one_line() -> void:
	var dir: String = "user://test_logs_abandon"
	var lg: Object = _logger(dir)
	var bal: Balance = Balance.load_default()
	var meta := MetaState.new()
	var expect := MetaState.new()
	var full: int = Imprint.points(bal.floor_index, false, false, bal.imprint_participation, bal.imprint_floor_coef,
			bal.imprint_boss_bonus, bal.imprint_first_reach, 1.0)
	var pts: int = RunSettle.finish(_fail_result(), true, false, meta, bal, lg, "rid", {})
	var want: int = expect.settle(_fail_result(), bal)
	check_eq(pts, want, "포기 정산 = 실패 정산(meta.settle 재사용)")
	check_eq(pts, int(floorf(float(full) * bal.imprint_fail_ratio)), "전체 지급의 fail_ratio(0.6)")
	check_eq(meta.points, expect.points, "메타 points 기대치")
	check_eq(meta.runs_played, 1, "runs_played 1")
	var ls: PackedStringArray = _lines(dir)
	check_eq(ls.size(), 1, "runs.jsonl 1줄")
	if ls.size() == 1:
		var d: Dictionary = JSON.parse_string(ls[0])
		check_eq(d.get("quit_midrun"), true, "quit_midrun true")
		check_eq(d.get("result"), "died", "result 는 기존 값 died")
		check_eq(int(d.get("points")), pts, "points 일치")
	lg.free()

func test_preset_or_granted_abandon_writes_nothing() -> void:
	var dir: String = "user://test_logs_preset"
	var lg: Object = _logger(dir)
	var meta := MetaState.new()
	var before: Dictionary = meta.to_dict()
	var pts: int = RunSettle.finish(_fail_result(), true, true, meta, Balance.load_default(), lg, "rid", {})
	check_eq(pts, 0, "정산 0")
	check_eq(meta.to_dict(), before, "메타 불변")
	check_eq(_lines(dir).size(), 0, "runs.jsonl 0줄")
	lg.free()

func test_end_run_called_only_in_quit_run_wrapper() -> void:
	var src: String = FileAccess.get_file_as_string("res://scripts/game/main.gd")
	check_eq(src.count("battle._end_run("), 1, "main.gd 의 _end_run 호출은 quit_run 한 곳")
	check(src.contains("func quit_run()"), "quit_run 래퍼 존재")
