class_name CaptureRig extends RefCounted
## 디버그 캡처 도구 (P3 C1·C2·C5). 디버그 빌드 전용.
## 호출부(main.gd)는 OS.is_debug_build() 가드 안에서 load() 로만 만든다. 이 폴더는 릴리스 export 에서 제외된다(AC-43).
## C1 HUD 숨김(호출부가 CanvasLayer 를 끈다), C2 월드 정지·한 프레임 이동(호출부가 스텝을 건너뛴다),
## C5 PNG 저장: user://captures/, 상한 200장, 가장 오래된 것부터 삭제. 삭제는 cap_ 접두사 생성물만 한다.

const DIR := "user://captures"
const PREFIX := "cap_"
const CAP := 200

## 생성물 중 가장 오래된 것부터 지워 cap 장 이하로 맞춘다. 지운 개수를 돌려준다.
static func prune(dir_path: String, cap: int = CAP) -> int:
	var da := DirAccess.open(dir_path)
	if da == null:
		return 0
	var names: Array[String] = []
	for f in da.get_files():
		if f.begins_with(PREFIX) and f.ends_with(".png"):
			names.append(f)
	names.sort()  # 파일명 앞부분이 유닉스 ms 라 사전순 = 시간순
	var removed := 0
	while names.size() > cap:
		da.remove(names.pop_front())
		removed += 1
	return removed

## 파일명: cap_<유닉스 ms 13자리>_<순번 4자리>.png
static func file_name(seq: int) -> String:
	return "%s%013d_%04d.png" % [PREFIX, int(Time.get_unix_time_from_system() * 1000.0), seq]

static var _git: String = ""

## git 짧은 해시. 첫 호출에 한 번만 조회해 캐시한다. 실패하면 "nogit".
static func git_short() -> String:
	if _git == "":
		var out: Array = []
		var code: int = OS.execute("git", ["rev-parse", "--short", "HEAD"], out)
		var s: String = String(out[0]).strip_edges() if code == 0 and out.size() > 0 else ""
		_git = s if s.length() <= 40 and _is_hex(s) else "nogit"
	return _git

static func _is_hex(s: String) -> bool:
	return s.length() > 0 and s.is_valid_hex_number(false)

## 순수 함수. ctx: preset(String, 빈 값이면 FREE), res(Vector2i), seed(int), t(float), git(String), now(유닉스 초, UTC).
## 형식 cap_{YYYYMMDD-HHMMSS}_{preset|FREE}_P{짧은변}_s{seed}_t{t:.2f}_{git}.png
static func build_name(ctx: Dictionary) -> String:
	var dt: Dictionary = Time.get_datetime_dict_from_unix_time(int(ctx.get("now", 0)))
	var preset: String = String(ctx.get("preset", ""))
	if preset == "":
		preset = "FREE"
	var res: Vector2i = ctx.get("res", Vector2i.ZERO)
	return "%s%04d%02d%02d-%02d%02d%02d_%s_P%d_s%d_t%.2f_%s.png" % [PREFIX, dt["year"], dt["month"], dt["day"],
		dt["hour"], dt["minute"], dt["second"], preset, mini(res.x, res.y), int(ctx.get("seed", 0)),
		float(ctx.get("t", 0.0)), String(ctx.get("git", "nogit"))]

## 충돌 시 확장자 앞에 -N (N=1부터)을 붙인 이름을 돌려준다.
static func unique_name(dir_path: String, fname: String) -> String:
	if not FileAccess.file_exists(dir_path.path_join(fname)):
		return fname
	var base: String = fname.trim_suffix(".png")
	var n: int = 1
	while FileAccess.file_exists(dir_path.path_join("%s-%d.png" % [base, n])):
		n += 1
	return "%s-%d.png" % [base, n]

## 다음 프레임이 그려진 뒤 화면을 PNG 로 저장한다. 저장 경로를 돌려준다.
## ctx 는 build_name 과 같은 키를 쓴다. res, git, now 가 없으면 여기서 채운다. 파일명은 cap_ 접두사를 유지한다(prune 한정).
func snap(tree: SceneTree, ctx: Dictionary = {}) -> String:
	await RenderingServer.frame_post_draw
	var img := tree.root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(DIR)
	var c: Dictionary = ctx.duplicate()
	if not c.has("res"):
		c["res"] = Vector2i(tree.root.size)
	if not c.has("git"):
		c["git"] = git_short()
	if not c.has("now"):
		c["now"] = int(Time.get_unix_time_from_system())
	var fname := unique_name(DIR, build_name(c))
	var path := DIR.path_join(fname)
	if img != null:
		img.save_png(path)
	prune(DIR)
	return path
