---
name: sample-clean
description: prose-pruner 자가 검증용 "위반 0건" 샘플. 3원칙 모두 통과하여 가지치기가 거의 일어나지 않아야 함. 임의 샘플명으로 실제 트리거 방지.
---

# GrepBridge 사용 규약

이 팀의 표준 코드 검색 도구. 세션 중 패턴 전수 조사 시 사용.

## 호출 포맷

```yaml
path: C:\works\<project>
patterns:
  - keyword: <regex>
    file_filter: "*.cpp"
    context: 3
```

## 트리거

- "함수 X 전체 호출처", "symbol 쓰임 전수"
- 3개 파일 미만 추정 시 Grep 직접 사용

## 결과 소비

`=== [패턴: K] ===` 블록 단위로 끊어 분석. 매칭 라인은 `← 매칭` 토큰으로 표시됨.

## 주의

- CP949 파일은 자동 디코딩, FFFD 발생 시 원본 인코딩 확인
- 1만 라인 초과 결과는 file_filter 로 좁힌 뒤 재검색
