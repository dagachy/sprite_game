extends Node
## WorldClock 코어를 씬 트리에서 쓰기 위한 얇은 오토로드 래퍼(UI 가 일시정지 이유를 걸 때 사용).
## 전투 시뮬(Battle)은 자체 WorldClock 을 가지므로 이 오토로드에 의존하지 않는다.

var core: WorldClock = WorldClock.new()
