class_name GameStrings extends RefCounted
## 문자열 상수 테이블. 문구는 storyteller.md §3.5 를 글자 그대로 옮긴다(임의 문구 금지).
## cut.clear*, res.* 문구는 storyteller 확정안이며 game-reviewer 검토 전 가정이다. 문구 변경은 이 테이블 한 곳에서만 한다.

const TABLE: Dictionary = {
	&"cut.intro1": "해가 뜨지 않는 세계. 마지막 열차가 멈췄다.",
	&"cut.intro2": "눈을 뜨자 낯선 승강장이었다. 손목엔 시계뿐.",
	&"cut.intro3": "왜 나일까. 레일 끝 새벽에 답이 있을 거다.",
	&"cut.clear1": "거대 그늘이 빛에 흩어졌다. 기억 조각이 하나 남았다.",
	&"cut.clear2": "레일은 더 깊은 곳으로 이어진다. 새벽은 아직 멀다.",
	# 결과 표기 (storyteller 제안 키 res.fell / res.currency)
	&"res.fell": "쓰러졌다",
	&"res.currency": "각인",
	&"res.cleared": "클리어",
	# UI 문구 (P0 최소, 문구 확정 전 가정)
	&"ui.title.start": "시작",
	&"ui.title.settings": "설정",
	&"ui.cut.skip": "건너뛰기",
	&"ui.cut.tap_hint": "탭하여 계속",
	&"ui.result.title": "판 결과",
	&"ui.result.again": "다시 하기",
	&"ui.result.home": "홈",
	&"ui.result.fell_note": "쓰러져도 각인은 남는다.",
	&"ui.result.no_record": "프리셋 판: 저장·기록 안 함",
	&"ui.pause.title": "일시정지",
	&"ui.pause.resume": "계속",
	&"ui.pause.settings": "설정",
	&"ui.pause.quit": "포기",
	&"ui.pause.confirm": "정말 포기할까요?\n각인은 60%만 받아요.",
	&"ui.pause.confirm_continue": "돌아가기",
	&"ui.pause.confirm_quit": "포기",
	&"ui.pause.button": "II",
	&"ui.settings.title": "설정",
	&"ui.settings.shake": "화면 흔들림",
	&"ui.settings.motion_reduced": "움직임 줄이기",
	&"ui.settings.haptics": "진동",
	&"ui.settings.on": "켜짐",
	&"ui.settings.off": "꺼짐",
	&"ui.settings.back": "뒤로",
	&"boss.intro": "거대 그늘이 길을 막는다",
}

const INTRO_KEYS: Array[StringName] = [&"cut.intro1", &"cut.intro2", &"cut.intro3"]
const CLEAR_KEYS: Array[StringName] = [&"cut.clear1", &"cut.clear2"]

## 키가 테이블에 모두 있을 때만 true. 클리어 컷은 false 면 건너뛴다.
static func has_keys(keys: Array[StringName]) -> bool:
	for k in keys:
		if get_text(k) == "":
			return false
	return not keys.is_empty()

## 금지어(storyteller 톤 규칙). 단위 테스트가 TABLE 전체를 검사한다.
## 키 접두사별 스캔 대상. cut.clear* 는 storyteller 문구가 들어오면 TABLE 에만 추가하면 같은 스캔을 탄다.
const SCAN_PREFIXES: Array[String] = ["cut.", "boss.", "res.", "ui."]
## 판 시작 전 대기 상한(초). 타이틀 1탭 + 컷 3장 최소 + 로딩 (ux-onboarding §2~4, D4)
const TITLE_TAP_SECONDS: float = 3.0
const LOAD_SECONDS_MAX: float = 1.5

const BANNED: Array[String] = ["사망", "죽", "패배", "잃", "포인트"]

static func get_text(key: StringName) -> String:
	return String(TABLE.get(key, ""))

static func find_banned(text: String) -> Array[String]:
	var out: Array[String] = []
	for w in BANNED:
		if text.contains(w):
			out.append(w)
	return out
