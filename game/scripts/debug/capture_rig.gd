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

var _seq: int = 0

## 다음 프레임이 그려진 뒤 화면을 PNG 로 저장한다. 저장 경로를 돌려준다.
## tag 가 있으면(프리셋 ID 등) 파일명 끝에 _<tag> 를 붙인다. 정렬·정리 규칙(접두사, 앞자리 ms)은 그대로 유지한다.
func snap(tree: SceneTree, tag: String = "") -> String:
	await RenderingServer.frame_post_draw
	var img := tree.root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(DIR)
	var fname := file_name(_seq)
	if tag != "":
		fname = fname.trim_suffix(".png") + "_" + tag + ".png"
	var path := DIR.path_join(fname)
	_seq += 1
	if img != null:
		img.save_png(path)
	prune(DIR)
	return path
