---
name: retry-safety
description: generator + verifier 를 MAX_RETRIES 상한 루프로 감싸 성공 또는 "escalated: N회 실패, 수동 개입 필요" 로 종결시키는 런타임 안전장치 진입점. 단일 fixture 또는 fixtures 디렉토리를 retry-safety-executor 에이전트로 실행하고 outcome.json + report.md 를 반환한다. 사용자가 "retry 상한", "무한 루프 방지", "max retries", "에스컬레이트 안전장치" 등을 요청할 때 사용.
---

# retry-safety

MAX_RETRIES 상한 재시도 안전장치 라우터.
단일 fixture / 다중 fixture 두 가지를 지원한다.

---

## 입력 fixture 규약

```
<fixture>/
├── fixture.json       # {"name","max_retries","expected":{"outcome","attempts"}}
├── generator.sh       # 호출: bash generator.sh <attempt> <out_file>. attempt는 1-origin.
└── verifier.sh        # 호출: bash verifier.sh <out_file>. exit 0 = PASS.
```

- generator 는 매 attempt 마다 `<out_file>` 를 새로 쓴다. 품질은 attempt 와 무관하거나 attempt 가 늘수록 좋아질 수 있다.

**왜:** attempt마다 새로 써야 이전 시도의 산출물이 다음 verifier 판정에 섞이지 않는다.
- verifier 는 산출물 1건의 PASS/FAIL 만 판정. 로그는 stdout/stderr 에.

**왜:** 판정을 exit code 하나로 고정해야 executor가 사람이 읽지 않고도 루프를 기계적으로 끊을 수 있다. 로그를 따로 빼는 것은 판정 신호와 설명을 섞지 않기 위해서다.

---

## 모드 결정

- 사용자가 fixture 디렉토리 1개를 주면 **단일 모드**.
- 상위 디렉토리를 주면서 "전체" 또는 "batch" 를 요청하면 **배치 모드** (`fixture.json` 을 가진 하위 디렉토리 전수 수집).

**왜:** 배치는 fixture 수만큼 상한 루프가 돌아 시간과 비용이 커지므로, 명시적으로 요청했을 때만 전수 실행한다.

---

## 단일 모드

입력: fixture 디렉토리 절대 경로 1개.

1. `retry-safety-executor` 에이전트를 1회 호출. 프롬프트에 `FIXTURE=<absolute path>` 전달.
2. executor 리포트와 산출물 경로(`<fixture>/result/{outcome.json,report.md,run.log,attempt_*.txt}`) 를 그대로 노출.
3. outcome 이 `escalated` 이면 "수동 개입 필요" 안내 1~2줄 재강조.

**왜:** escalated는 자동 재시도가 상한까지 소진된 상태라 더 돌려도 나아지지 않으므로, 사람이 원인을 보도록 넘기는 것이 이 스킬의 종결 지점이다.

---

## 배치 모드

입력: 상위 디렉토리 (`samples/`, `fixtures/` 등).

1. 각 fixture 마다 executor 를 **직렬 호출** (상한 루프끼리 리소스 경합 방지).

**왜:** 병렬로 돌리면 generator 실행 시간이 서로 간섭해 duration_ms와 `RS_ATTEMPT_TIMEOUT_MS` 판정이 흔들리므로, 직렬이어야 각 fixture의 시간 측정이 깨끗하다.
2. 집계 표:

```
| Fixture | outcome    | attempts/max | duration_ms | self-check |
|---------|------------|--------------|-------------|------------|
```

3. 표 끝에 `escalated N / success M / 전체 K` 요약 1줄.

---

## 임계값 override

- `RS_MAX_RETRIES` (기본: fixture.json 의 `max_retries`, 없으면 3): 상한 재지정. 디버깅용. 운영에서는 fixture.json 값을 신뢰할 것.

**왜:** 상한을 바꾸면 같은 fixture의 attempts 결과가 달라져 `expected` 와의 self-check 비교가 무의미해지므로, 운영은 fixture.json 값에 고정한다.
- `RS_ATTEMPT_TIMEOUT_MS` (기본 `60000`): generator 1회 실행 최대 허용 시간. 초과 시 해당 attempt FAIL + run.log 에 `timed_out=true`.

**왜:** generator 하나가 멈춰도 전체 상한 루프가 묶이지 않도록 attempt 단위로 끊어, 다음 재시도로 넘어갈 수 있게 한다.
- `RS_ESCALATE_MESSAGE` (기본 `"escalated: {N}회 실패, 수동 개입 필요"` — 책 p140 문구): 조직 템플릿으로 교체 가능. `{N}` 은 치환 토큰.

**왜:** 로그 끝의 종결 문구는 사람이 실패를 찾아내는 신호이므로, 교체하더라도 "수동 개입 필요"라는 의미는 남겨야 에스컬레이션이 누락되지 않는다.

---

## 자가 검증

플러그인 내장 샘플 fixture 2건:

```
<플러그인 루트>/.claude/skills/retry-safety/samples/
├── success/      # 2회차에 PASS → outcome=success, attempts=2
└── escalation/   # 3회 전부 FAIL → outcome=escalated, attempts=3
```

executor 가 `fixture.json.expected` 와 비교해 `[self-check] PASS|FAIL` 을 report.md 끝에 1줄 추가한다. 2/2 PASS 가 정상.

**왜:** 두 샘플은 성공 경로와 에스컬레이트 경로를 각각 대표하므로, 둘 다 맞아야 루프의 종료 조건이 양쪽에서 올바르게 동작한다고 볼 수 있다.

---

## 범용 적용 메모

이 스킬은 "measure" 플러그인의 런타임 안전장치다. **무한 재시도** 는 이 책의 안티패턴 #2 (ex-08-33) — 생성·검증 루프를 짤 때 반드시 상한을 둘 것.

**왜:** verifier가 계속 FAIL을 내면 상한이 없는 루프는 비용과 시간을 무한히 쌓으므로, 상한 없는 재시도 루프는 허용하지 않는다.

- 상한 소진 후 **반드시 사람에게 넘기는 문구** 가 로그 끝에 남는다 (관측·에스컬레이션 가능성 확보).

**왜:** 상한에 닿고도 계속 재시도하면 비용이 끝없이 쌓이므로, 사람에게 넘기는 지점을 로그에 남겨 막힌 건수를 나중에 셀 수 있게 한다.
- 상한 자체는 fixture 당 결정 — 책 기본 3 은 "짧은 피드백 사이클" 전제. 비용/시간이 큰 작업은 더 낮게.

**왜:** 기본 3회는 한 번의 피드백 사이클이 짧은 작업을 가정한 값이라, 한 번 시도에 비용이 큰 작업에서는 같은 상한도 낭비가 된다.
- generator 가 **매번 같은 산출물** 을 내면 재시도는 무의미 — 입력(spec/seed/noise)에 변화를 주거나, 상한을 1로 두고 즉시 escalate.

**왜:** 같은 산출물이 반복되면 attempt를 늘려도 얻는 것이 없고, 재시도 비용만 쓴 채 같은 실패로 끝난다.
