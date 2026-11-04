---
name: data-exporter
description: 데이터를 지정된 형식(CSV, Excel)으로 내보낸다. 건수와 보안 요건에 따라 처리 방식이 달라진다.
type: skill
tools: Read, Bash, Write
---

# data-exporter

데이터를 파일로 내보낸다.

## 언제 사용하나

- "데이터 내보내줘", "엑셀로 뽑아줘"라고 요청할 때
- 정기 보고용 데이터 추출이 필요할 때

---

## 흐름

### 1단계: 내보낼 데이터 확인

사용자로부터 다음 정보를 확인한다.

- 대상 테이블 또는 쿼리
- 기준 기간
- 출력 형식 (CSV / Excel)
- 예상 건수

### 2단계: 처리 방식 결정

예상 건수를 기준으로 처리 방식을 결정한다.

10만 건 초과이면 → batch-exporter 스킬 참조

10만 건 이하는 아래 3단계로 직접 처리한다.

### 3단계: 데이터 추출

```bash
python3 export/query.py \
  --table {TABLE} \
  --from {START} \
  --to {END} \
  --output raw/export.csv
```

추출 후 건수를 확인한다.

```bash
wc -l raw/export.csv
```

### 4단계: 형식 변환

출력 형식에 따라 변환한다.

CSV 형식을 요청한 경우 raw/export.csv를 그대로 사용한다.

Excel 형식을 요청한 경우 다음 명령으로 변환한다.

```bash
python3 export/to_excel.py \
  --input raw/export.csv \
  --output export.xlsx
```

개인정보 포함이면 → secure-exporter 스킬 참조

### 5단계: 결과 전달

변환된 파일 경로와 건수를 사용자에게 보고한다.

```
완료: export.xlsx (12,345건)
```
