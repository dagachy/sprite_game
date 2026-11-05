extends TestCase
## TD 결정 4: build_name 형식·충돌, prune 의 cap_ 한정, CAP-04 사망 실패 상태(PNG 없음), hide_offer 프리셋.

const TDIR := "user://test_capture_rig"

func _clean() -> void:
	DirAccess.make_dir_recursive_absolute(TDIR)
	var da := DirAccess.open(TDIR)
	for f in da.get_files():
		da.remove(f)

func _ctx(preset: String) -> Dictionary:
	return {"preset": preset, "res": Vector2i(1080, 1920), "seed": 12345, "t": 48.8123, "git": "abc1234", "now": 1730822400}

func test_build_name_format() -> void:
	var rx := RegEx.new()
	rx.compile("^cap_\\d{8}-\\d{6}_(CAP-0[1-6]|FREE)_P\\d+_s\\d+_t\\d+\\.\\d{2}_[0-9a-z]+\\.png$")
	var n: String = CaptureRig.build_name(_ctx("CAP-02"))
	check(rx.search(n) != null, "matches pattern: " + n)
	check_eq(n, "cap_20241105-160000_CAP-02_P1080_s12345_t48.81_abc1234.png", "exact name")
	check(CaptureRig.build_name(_ctx("")).contains("_FREE_"), "empty preset is FREE")
	var c := _ctx("CAP-01"); c["res"] = Vector2i(1920, 1080); c["git"] = "nogit"
	check(CaptureRig.build_name(c).contains("_P1080_"), "short side")
	check(CaptureRig.build_name(c).ends_with("_nogit.png"), "nogit fallback name")

func test_unique_name_collision_suffix() -> void:
	_clean()
	var n: String = CaptureRig.build_name(_ctx("CAP-01"))
	check_eq(CaptureRig.unique_name(TDIR, n), n, "no collision keeps name")
	for suffix in ["", "-1"]:
		var fa := FileAccess.open(TDIR.path_join(n.trim_suffix(".png") + suffix + ".png"), FileAccess.WRITE)
		fa.store_string("x")
		fa.close()
	check_eq(CaptureRig.unique_name(TDIR, n), n.trim_suffix(".png") + "-2.png", "-2 after name and -1 exist")
	_clean()

func test_prune_only_touches_cap_files() -> void:
	_clean()
	for i in 4:
		var fa := FileAccess.open(TDIR.path_join(CaptureRig.build_name(_ctx("CAP-0%d" % (i + 1)))), FileAccess.WRITE)
		fa.store_string("x")
		fa.close()
	for other in ["notes.txt", "keep.png"]:
		var fb := FileAccess.open(TDIR.path_join(other), FileAccess.WRITE)
		fb.store_string("x")
		fb.close()
	check_eq(CaptureRig.prune(TDIR, 2), 2, "two cap files removed")
	var da := DirAccess.open(TDIR)
	check(da.file_exists("notes.txt") and da.file_exists("keep.png"), "non-cap files kept")
	_clean()

func test_cap04_death_before_offer_is_failure_without_png() -> void:
	var bal := Balance.load_default()
	var b := CapturePresets.make_battle(&"CAP-04", bal, ChunkDb.load_all(), MetaState.new())
	var god_before: bool = b.god_mode
	var state: Dictionary = {}
	CapturePresets.advance_chunk(b, &"CAP-04", state, 5)
	check(not CapturePresets.reach_failed(b, &"CAP-04"), "alive is not failure")
	b.hurt(1.0e9, &"test", true)
	check(b.ended, "battle ended by death")
	check(CapturePresets.advance_chunk(b, &"CAP-04", state, 5), "advance reports done")
	check(CapturePresets.reach_failed(b, &"CAP-04"), "death before offer is failure")
	check_eq(b.god_mode, god_before, "god unchanged")
	# 실패 판정은 PNG 를 만드는 snap 을 부르지 않는다: 호출부 규칙. 여기서는 captures 폴더에 새 파일이 없음을 확인한다.
	_clean()
	check_eq(DirAccess.open(TDIR).get_files().size(), 0, "no png produced")
	check(not CapturePresets.reach_failed(b, &"CAP-01"), "non-offer preset never reach-fails")

func test_hide_offer_presets_hide_box_but_keep_pick_pending() -> void:
	for id in [&"CAP-01", &"CAP-02", &"CAP-03"]:
		check(CapturePresets.hides_offer(id), "%s hides offer" % String(id))
	for id in [&"CAP-04", &"CAP-05", &"CAP-06"]:
		check(not CapturePresets.hides_offer(id), "%s shows offer" % String(id))
	# 숨김 판정은 battle 을 건드리지 않는다: awaiting_pick 유지
	var b := CapturePresets.make_battle(&"CAP-04", Balance.load_default(), ChunkDb.load_all(), MetaState.new())
	var state: Dictionary = {}
	while not CapturePresets.advance_chunk(b, &"CAP-04", state, 400):
		pass
	check(b.awaiting_pick, "pick pending at stop")
	CapturePresets.hides_offer(&"CAP-01")
	check(b.awaiting_pick, "awaiting_pick unchanged by hide query")
	check(not OfferLock.accepts(false, true), "hidden box ignores input")
	check(not OfferLock.accepts(true, false), "locked ignores input")
	check(OfferLock.accepts(false, false), "visible unlocked accepts")
