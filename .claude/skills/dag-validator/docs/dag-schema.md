# tasks.json DAG 스키마 (ex-11-05 + ex-13-01 원칙)

## 스키마

```json
{
  "tasks": [
    {"id": "<string>", "depends_on": ["<id>", ...]}
  ]
}
```

필드:
- `id` (string, 필수, unique): 작업 식별자.
- `depends_on` (array of ids, 선택): 선행 작업 id 목록. 생략 시 빈 배열.

## 검증 항목

| 항목 | 설명 | Verdict |
|------|------|---------|
| 순환 | DFS 3-color로 cycle 감지. | CYCLE |
| Dangling | depends_on에 존재하지 않는 id 참조. | DANGLING |
| 병렬 레벨 | Kahn's algorithm으로 topological levels 산출. | 참고 정보 |

## 왜 이게 중요한가

책 ex-11-05 (6-Phase 오케스트레이터): Phase 간 의존성이 명시되어야 어떤 Phase가 병렬 가능한지 자동 추출됨.
책 ex-13-01 (dependency-mapper): batches.json으로 선언된 작업 그래프는 순환이 있으면 작업자가 영원히 블록됨.

## 범위 밖

- 작업 소요시간/비용 예측.
- 조건부 의존성 (`if<branch> then depends_on <X>`).
- 외부 리소스 의존성 (파일 lock, DB 등).
