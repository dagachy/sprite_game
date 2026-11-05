class_name Flow extends RefCounted
## 판 밖 흐름 상태기계: TITLE, INTRO, RUN, PAUSE, RESULT, SETTINGS (decision5 D5).
## 순수 로직(노드 없음). main.gd 가 소유하고 state_changed 로 화면을 전환한다.
##
## === UI 계약 (ui-implementer) ===
## 시그널
##   state_changed(old: State, new: State)  화면 전환 트리거
##   run_requested()                        main 이 start_run() 호출해야 함(RUN 진입 직후)
## UI -> Flow 진입 메서드
##   타이틀 "시작" 1탭      -> press_start()      (first_run_done=false 면 INTRO, 아니면 RUN)
##   타이틀 설정 버튼       -> open_settings()  / 설정 닫기 -> close_settings()
##   컷 종료(finished 시그널, 스킵 포함) -> intro_finished()  (이때 first_run_done 저장)
##   일시정지 버튼/재개     -> pause() / resume()
##   일시정지 포기 확정     -> abandon(no_record)  (일반 판: RESULT, 프리셋·부여 판: TITLE)
##   결과 화면 "다시"       -> retry()   / "타이틀" -> quit_to_title()
## main 이 판 종료 시 -> run_ended() (RUN -> RESULT)
## 컷 재생은 CutPlayer: start(GameStrings.INTRO_KEYS), update(dt), tap(), skip(); cut_shown/finished 시그널.
## 부팅: boot(use_direct) 한 번 호출. 디버그 빌드/프리셋/캡처/디버그 부여 경로는 use_direct=true 로 TITLE 생략.
##   직접 경로는 settings 를 읽지도 쓰지도 않는다.

enum State { TITLE, INTRO, RUN, PAUSE, RESULT, SETTINGS }

signal state_changed(old: State, new: State)
signal run_requested()
signal abandoned()   # 일반 판 포기 확정. main 이 정산·기록 후 run_ended() 로 RESULT 진입

var state: State = State.TITLE
var settings: SettingsStore
var direct_run: bool = false      # 직접 경로 판이면 first_run_done 을 건드리지 않는다
var _settings_return: State = State.TITLE

func _init(store: SettingsStore = null) -> void:
	settings = store if store != null else SettingsStore.new()

## 릴리스 판단: 디버그 빌드, 프리셋·캡처 인자, 디버그 부여 중 하나라도 있으면 직접 경로
static func should_skip_title(is_debug: bool, has_preset: bool, debug_granted: bool) -> bool:
	return is_debug or has_preset or debug_granted

func boot(use_direct: bool) -> void:
	direct_run = use_direct
	if use_direct:
		_enter(State.RUN)
		run_requested.emit()
		return
	settings.load_file()   # 실패해도 기본값(first_run_done=false)으로 진행
	_enter(State.TITLE)

func press_start() -> void:
	if state != State.TITLE:
		return
	if settings.first_run_done():
		_begin_run()
	else:
		_enter(State.INTRO)

func intro_finished() -> void:
	if state != State.INTRO:
		return
	if not direct_run:
		settings.set_value("first_run_done", true)   # 저장 실패해도 진행
	_begin_run()

func run_ended() -> void:
	if state == State.RUN or state == State.PAUSE:   # PAUSE: 포기 정산 경로
		_enter(State.RESULT)

func pause() -> void:
	if state == State.RUN:
		_enter(State.PAUSE)

func resume() -> void:
	if state == State.PAUSE:
		_enter(State.RUN)

## 포기 확정(PAUSE 확인 대화상자 이후). no_record: 프리셋·부여 판이면 true -> 결과 없이 TITLE.
## 일반 판은 abandoned 를 내보내고, main 이 정산하면 run_ended() 로 RESULT 가 된다.
func abandon(no_record: bool) -> void:
	if state != State.PAUSE:
		return
	if no_record:
		_enter(State.TITLE)
	else:
		abandoned.emit()

func retry() -> void:
	if state == State.RESULT:
		_begin_run()

func quit_to_title() -> void:
	if state == State.RESULT:   # PAUSE 에서의 포기는 abandon() 을 쓴다
		_enter(State.TITLE)

func open_settings() -> void:
	if state == State.TITLE or state == State.PAUSE:
		_settings_return = state
		_enter(State.SETTINGS)

func close_settings() -> void:
	if state == State.SETTINGS:
		_enter(_settings_return)

func _begin_run() -> void:
	_enter(State.RUN)
	run_requested.emit()

func _enter(s: State) -> void:
	var old: State = state
	state = s
	state_changed.emit(old, s)
