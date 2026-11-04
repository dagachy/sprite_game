extends Node
## 32색 공용 팔레트 (art-audio §A.2). 슬롯 번호와 const 이름이 1:1. 신호색(15~26)은 지형에 쓰지 않는다.
## 오토로드 이름이 Palette 이므로 class_name 은 쓰지 않는다. 사용: Palette.CORE

const VOID := Color("14161F")
const T1 := Color("1F222E")
const T2 := Color("2B3040")
const T3 := Color("383E52")
const T4 := Color("485068")
const T5 := Color("5E677F")
const T6 := Color("7A849C")
const T7 := Color("9CA6BC")
const COVER_D := Color("4A3C36")
const COVER_M := Color("6E5A4C")
const COVER_L := Color("A08A74")
const HAZ_D := Color("2E1838")
const HAZ_M := Color("522A66")
const HAZ_B := Color("8A3FA8")
const CORE := Color("3DF0FF")
const CORE_S := Color("1B9FB5")
const ALLY_BUL := Color("D8FFFF")
const ENM_BUL_A := Color("FF5A1F")
const ENM_BUL_B := Color("FFA126")
const DANGER := Color("FF2D55")
const GOLD := Color("FFD83A")
const GOLD_S := Color("B88A12")
const EYE := Color("FFF6D6")
const HEAL := Color("5BE37D")
const XP := Color("2FD7C0")
const WHITE := Color("FFFFFF")
const OUTLINE := Color("0A0B10")
const SKIN_SWORD := Color("4A78E0")
const SKIN_ARCH := Color("C9A0FF")
const ENM_A := Color("D4735C")
const ENM_B := Color("78B0D0")
const ELITE := Color("D0508A")

## z_index 표 (art §A.5 + 메인 결정: 적 탄을 아군 탄 위로)
const Z_FLOOR := -50
const Z_HAZARD := -40
const Z_WALL := -30
const Z_DECAL := -10
const Z_PICKUP := 0
const Z_ENEMY := 10
const Z_PLAYER := 20
const Z_ALLY_BULLET := 30
const Z_ENEMY_BULLET := 35
const Z_FX := 40
