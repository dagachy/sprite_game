---
name: report-lifecycle-manager
description: 주간·월간·분기 보고서의 요청 접수, 데이터 수집, 검증, 분석, 초안 작성, 내부 검토, 수정 확정, 배포, 피드백 수집, 아카이브까지 전 생애주기를 단일 스킬에서 관리한다.
type: skill
tools: Read, Write, Bash, Glob
---

# report-lifecycle-manager

보고서 생성부터 아카이브까지 전 과정을 수행한다.

## 언제 사용하나

- "주간 보고서 만들어줘", "월간 보고서 작성해줘"라고 요청할 때
- 보고서 데이터 수집·검증이 필요할 때
- 초안 작성 후 검토자에게 공유가 필요할 때
- 최종 보고서 배포 및 아카이브가 필요할 때

---

## Phase 1: 요청 접수 및 분류

### 1.1 보고서 유형 파악

사용자로부터 보고서 유형을 확인한다.

보고서 유형 목록:
- 주간 업무 보고서 (매주 금요일 오후 5시 기준)
- 월간 성과 보고서 (매월 말일 기준)
- 분기 경영 보고서 (3·6·9·12월 말 기준)
- 수시 이슈 보고서 (발생 즉시)

유형이 명확하지 않으면 사용자에게 확인한다.

### 1.2 기준 기간 확인

보고서의 집계 기간을 확인한다.

```
주간: {N}주차 (YYYY-MM-DD ~ YYYY-MM-DD)
월간: YYYY년 MM월
분기: YYYY년 N분기
```

사용자가 기간을 지정하지 않으면 가장 최근 완료된 기간을 기본값으로 제안한다.

### 1.3 수신자 목록 확인

보고서를 받아볼 수신자를 확인한다.

수신자 유형:
- 팀 내부 (팀장, 팀원)
- 유관 부서 (기획, 운영, 마케팅)
- 경영진 (본부장, C-레벨)

수신자 유형에 따라 상세 수준을 조정한다:
- 경영진 → 요약 중심, 수치 강조
- 팀 내부 → 상세 진행 현황 포함
- 유관 부서 → 협업 항목 중심

### 1.4 보고서 템플릿 선택

보고서 유형·수신자에 맞는 템플릿을 선택한다.

```bash
ls templates/reports/
```

템플릿 파일이 없으면 기본 구조로 신규 생성한다:
- 표지 (제목, 작성자, 작성일, 기준기간)
- 요약 섹션
- 본문 섹션
- 첨부 섹션

---

## Phase 2: 데이터 수집

### 2.1 데이터 소스 목록 확인

보고서에 필요한 데이터 소스를 파악한다.

일반적인 데이터 소스:
- 업무 관리 시스템 (Jira, Redmine)
- 소스 관리 시스템 (SVN, Git)
- 빌드 및 배포 이력
- 이슈 트래커
- 고객 지원 티켓 시스템

### 2.2 Jira 데이터 수집

해당 기간의 Jira 이슈를 수집한다.

```bash
jira-cli list \
  --project PROJ \
  --created "YYYY-MM-DD..YYYY-MM-DD" \
  --status Done \
  --format json > raw/jira-done.json
```

수집 항목:
- 완료 이슈 수
- 이슈별 유형 (버그, 기능, 개선, 작업)
- 이슈별 담당자
- 이슈별 처리 소요 시간 (생성일 → 완료일)
- 재오픈 이슈 수

```bash
jira-cli list \
  --project PROJ \
  --created "YYYY-MM-DD..YYYY-MM-DD" \
  --status "In Progress" \
  --format json > raw/jira-inprogress.json
```

진행 중 이슈 수집:
- 현재 진행 중인 이슈 목록
- 예상 완료일 초과 여부
- 블로커 이슈 여부

```bash
jira-cli list \
  --project PROJ \
  --created "YYYY-MM-DD..YYYY-MM-DD" \
  --priority Critical,Blocker \
  --format json > raw/jira-critical.json
```

### 2.3 SVN 커밋 이력 수집

해당 기간의 SVN 커밋을 수집한다.

```bash
svn log -r {STARTREV}:{ENDREV} \
  --xml \
  --verbose \
  http://svn.company.com/repos/project > raw/svn-log.xml
```

수집 항목:
- 커밋 수 (총계, 담당자별)
- 커밋 대상 경로 (모듈별)
- 커밋 메시지 키워드 (bugfix, hotfix, feature 등)
- 커밋 파일 변경량 (추가·수정·삭제 파일 수)

### 2.4 빌드 이력 수집

빌드 서버에서 빌드 결과를 수집한다.

```bash
curl -s "http://ci.company.com/api/builds?from={DATE}&to={DATE}" \
  -H "Authorization: Bearer $CI_TOKEN" \
  > raw/builds.json
```

수집 항목:
- 총 빌드 수
- 성공 빌드 수 / 실패 빌드 수
- 빌드 성공률 (%)
- 평균 빌드 소요 시간
- 최장 빌드 소요 시간

---

## Phase 3: 데이터 검증

### 3.1 수집 완료 여부 확인

수집된 raw 데이터 파일이 모두 존재하는지 확인한다.

```bash
ls -la raw/
```

누락된 파일이 있으면 해당 Phase 2 단계로 돌아가 재수집한다.

### 3.2 기간 정합성 검증

수집된 데이터의 기간이 요청 기준 기간과 일치하는지 확인한다.

Jira 데이터 기간 검증:
```bash
python3 scripts/validate_period.py raw/jira-done.json --start {DATE} --end {DATE}
```

SVN 데이터 기간 검증:
```bash
python3 scripts/validate_svn_period.py raw/svn-log.xml --start {DATE} --end {DATE}
```

기간 불일치 시 사용자에게 확인 후 재수집 또는 조정한다.

### 3.3 데이터 이상치 탐지

수집된 수치에 비정상적인 값이 있는지 확인한다.

이상치 기준:
- 완료 이슈 수가 이전 기간 대비 50% 이상 감소
- 빌드 성공률이 70% 미만
- 커밋 수가 이전 기간 대비 80% 이상 감소

이상치 탐지 시 원인을 사용자에게 확인한다:
- 공휴일·연휴 포함 여부
- 특이 사항 (장애, 긴급 대응, 행사 등)

이상치가 확인된 경우 보고서 본문에 주석을 추가한다.

### 3.4 담당자 데이터 정합성 확인

수집된 이슈·커밋의 담당자 이름이 팀원 목록과 일치하는지 확인한다.

```bash
python3 scripts/validate_authors.py raw/ --team-list config/team.json
```

매핑되지 않는 사용자가 있으면 config/team.json에 추가하거나 제외 처리한다.

---

## Phase 4: 분석 및 집계

### 4.1 이슈 분석

수집된 Jira 데이터를 분석한다.

```bash
python3 scripts/analyze_jira.py raw/jira-done.json raw/jira-inprogress.json \
  --output analysis/jira-stats.json
```

생성 지표:
- 유형별 완료 이슈 수 (버그/기능/개선/작업)
- 담당자별 완료 이슈 수
- 평균 이슈 처리 소요 시간 (일)
- 재오픈률 (재오픈 이슈 수 / 전체 완료 이슈 수)
- 기간 내 신규 생성 이슈 수 vs 완료 이슈 수 (순증감)

### 4.2 커밋 분석

수집된 SVN 데이터를 분석한다.

```bash
python3 scripts/analyze_svn.py raw/svn-log.xml \
  --output analysis/svn-stats.json
```

생성 지표:
- 총 커밋 수
- 담당자별 커밋 수
- 모듈별 커밋 수
- 커밋 유형별 분류 (bugfix, feature, refactor, docs)
- 일별 커밋 분포 (활동 열지도용)

### 4.3 빌드 분석

```bash
python3 scripts/analyze_builds.py raw/builds.json \
  --output analysis/build-stats.json
```

생성 지표:
- 빌드 성공률 (%)
- 평균 빌드 시간 (분)
- 실패 원인 분류 (컴파일 오류, 테스트 실패, 타임아웃)
- 시간대별 빌드 분포

### 4.4 종합 KPI 산출

```bash
python3 scripts/compute_kpi.py \
  analysis/jira-stats.json \
  analysis/svn-stats.json \
  analysis/build-stats.json \
  --output analysis/kpi.json
```

종합 KPI:
- 이슈 처리 완료율 (완료 / (완료 + 진행 중))
- 결함 밀도 (버그 수 / 전체 커밋 수)
- 빌드 안정성 지수 (성공 빌드 수 / 전체 빌드 수)
- 팀 활동 지수 (커밋 수 + 이슈 완료 수 합산)

---

## Phase 5: 보고서 초안 작성

### 5.1 표지 생성

```bash
python3 scripts/gen_cover.py \
  --title "{보고서 유형} 보고서" \
  --period "{기준기간}" \
  --author "{작성자}" \
  --date "$(date +%Y-%m-%d)" \
  --output draft/00_cover.md
```

### 5.2 요약 섹션 생성

분석 결과를 바탕으로 요약 섹션을 작성한다.

```bash
python3 scripts/gen_summary.py \
  analysis/kpi.json \
  --output draft/01_summary.md
```

요약 섹션 구성:
- 이번 기간 하이라이트 (최대 3줄)
- 주요 KPI 테이블 (이전 기간 대비 변화량 포함)
- 특이사항 및 주의사항 (있는 경우)

### 5.3 이슈 현황 섹션 생성

```bash
python3 scripts/gen_issue_section.py \
  analysis/jira-stats.json \
  --output draft/02_issues.md
```

섹션 구성:
- 완료 이슈 요약 테이블
- 진행 중 이슈 목록 (완료 예정일 포함)
- 이슈 유형별 분포 차트 (Mermaid 파이 차트)
- 재오픈 이슈 특이사항

### 5.4 개발 활동 섹션 생성

```bash
python3 scripts/gen_dev_section.py \
  analysis/svn-stats.json \
  analysis/build-stats.json \
  --output draft/03_dev.md
```

섹션 구성:
- 커밋 현황 요약 테이블
- 모듈별 변경 빈도 차트
- 빌드 성공률 추이 (주별 꺾은선 그래프용 데이터)
- 주요 변경 내역 (커밋 메시지 요약)

### 5.5 이슈·리스크 섹션 작성

분석 중 발견된 이상치·리스크를 정리한다.

```bash
python3 scripts/gen_risk_section.py \
  analysis/ \
  --output draft/04_risks.md
```

포함 항목:
- 처리 기한 초과 이슈 목록
- 재오픈 빈도 높은 이슈
- 빌드 실패 반복 패턴
- 담당자 편중 (특정 담당자에게 이슈가 집중된 경우)

### 5.6 초안 병합

각 섹션 파일을 하나의 보고서로 병합한다.

```bash
cat draft/00_cover.md \
    draft/01_summary.md \
    draft/02_issues.md \
    draft/03_dev.md \
    draft/04_risks.md \
  > draft/report-draft.md
```

---

## Phase 6: 내부 검토

### 6.1 검토자 지정

보고서 검토자를 확인한다. 기본 검토자는 팀장이다.

```bash
cat config/reviewers.json
```

### 6.2 검토 요청 발송

검토자에게 보고서 초안을 공유한다.

```bash
python3 scripts/send_review_request.py \
  --draft draft/report-draft.md \
  --reviewers config/reviewers.json \
  --subject "[검토 요청] {보고서 제목}" \
  --deadline "YYYY-MM-DD 17:00"
```

### 6.3 검토 의견 수렴 대기

검토자가 의견을 회신할 때까지 대기한다. 기한(기본 24시간) 내 회신이 없으면 리마인더를 발송한다.

```bash
python3 scripts/send_reminder.py \
  --draft-id {ID} \
  --hours-overdue 4
```

### 6.4 검토 의견 취합

수신된 검토 의견을 취합한다.

```bash
python3 scripts/collect_review_comments.py \
  --draft-id {ID} \
  --output review/comments.json
```

의견 분류:
- 필수 수정 (Blocker)
- 권고 수정 (Major)
- 제안 (Minor)

---

## Phase 7: 수정 및 확정

### 7.1 필수 수정 항목 처리

검토 의견 중 Blocker 항목을 처리한다.

```bash
python3 scripts/apply_corrections.py \
  --draft draft/report-draft.md \
  --comments review/comments.json \
  --severity blocker \
  --output draft/report-draft-v2.md
```

수정 후 검토자에게 재확인 요청한다 (Blocker가 있는 경우만).

### 7.2 권고 수정 항목 검토

Major 항목은 내용을 검토한 후 반영 여부를 결정한다.

반영 판단 기준:
- 수치 오류, 누락된 내용: 반드시 반영
- 표현 방식, 순서 변경: 작성자 판단
- 추가 분석 요청: 시간 여건에 따라 결정

### 7.3 최종본 생성

수정 사항을 모두 반영한 최종본을 생성한다.

```bash
cp draft/report-draft-v2.md final/report-{DATE}-{TYPE}.md
```

최종본 메타데이터 기록:
```bash
echo "{\"version\": \"final\", \"date\": \"{DATE}\", \"type\": \"{TYPE}\", \"author\": \"{AUTHOR}\"}" \
  > final/report-{DATE}-{TYPE}-meta.json
```

### 7.4 최종본 PDF 변환 (선택)

경영진 보고 시 PDF 변환이 필요한 경우:

```bash
pandoc final/report-{DATE}-{TYPE}.md \
  --pdf-engine=xelatex \
  --template templates/report.tex \
  -o final/report-{DATE}-{TYPE}.pdf
```

---

## Phase 8: 배포 및 공유

### 8.1 공유 채널 결정

수신자 유형별 공유 채널을 결정한다.

| 수신자 | 채널 |
|--------|------|
| 팀 내부 | Slack #team-report |
| 유관 부서 | 이메일 |
| 경영진 | 이메일 + 별도 보고 |

### 8.2 Slack 공유

팀 채널에 보고서 링크를 공유한다.

```bash
python3 scripts/slack_post.py \
  --channel "#team-report" \
  --message "[{보고서 제목}] 첨부파일을 확인해 주세요." \
  --file final/report-{DATE}-{TYPE}.md
```

### 8.3 이메일 발송

유관 부서·경영진에게 이메일을 발송한다.

```bash
python3 scripts/send_email.py \
  --to config/recipients.json \
  --subject "[{보고서 제목}]" \
  --body templates/email-body.txt \
  --attachment final/report-{DATE}-{TYPE}.pdf
```

### 8.4 Confluence 업로드 (선택)

팀 위키에 보고서를 업로드한다.

```bash
python3 scripts/confluence_upload.py \
  --space TEAM \
  --parent-page "정기 보고서" \
  --title "{보고서 제목}" \
  --file final/report-{DATE}-{TYPE}.md
```

---

## Phase 9: 피드백 수집

### 9.1 피드백 요청 발송

보고서 배포 후 48시간 이내에 피드백 요청을 발송한다.

```bash
python3 scripts/send_feedback_request.py \
  --report-id {ID} \
  --deadline "YYYY-MM-DD 17:00"
```

피드백 항목:
- 보고서 유용성 평가 (1~5)
- 누락된 정보 여부
- 개선 제안

### 9.2 피드백 수집 및 분석

```bash
python3 scripts/collect_feedback.py \
  --report-id {ID} \
  --output feedback/report-{DATE}.json
```

### 9.3 개선 항목 등록

피드백에서 도출된 개선 항목을 다음 회차 보고서 작업 시 반영할 수 있도록 기록한다.

```bash
python3 scripts/log_improvements.py \
  --feedback feedback/report-{DATE}.json \
  --improvement-log logs/improvements.json
```

---

## Phase 10: 아카이브

### 10.1 아카이브 디렉토리 구조

```
archive/
  YYYY/
    MM/
      report-YYYYMMDD-{TYPE}/
        raw/          ← 원본 수집 데이터
        analysis/     ← 분석 결과
        draft/        ← 초안 이력
        final/        ← 최종 배포본
        feedback/     ← 피드백 결과
```

### 10.2 아카이브 실행

```bash
python3 scripts/archive.py \
  --report-id {ID} \
  --archive-root archive/
```

### 10.3 임시 파일 정리

```bash
rm -rf raw/ draft/ review/
```

### 10.4 아카이브 인덱스 갱신

```bash
python3 scripts/update_archive_index.py \
  --archive-root archive/ \
  --output archive/index.json
```

---

## 공통 오류 처리

### 데이터 수집 실패

수집 API 또는 CLI 호출이 실패한 경우:

1. 네트워크 연결 확인
2. 인증 토큰 만료 여부 확인
3. 30초 대기 후 1회 재시도
4. 2회 연속 실패 시 사용자에게 보고

### 스크립트 실행 오류

```bash
python3 scripts/xxx.py
```

실행 오류 발생 시:
1. stderr 메시지 확인
2. Python 패키지 의존성 확인: `pip install -r requirements.txt`
3. 설정 파일(config/) 누락 여부 확인

### 파일 용량 초과

보고서 PDF 용량이 10MB를 초과하면 이미지 품질을 낮춘다:

```bash
pandoc ... --variable=imagequality:72
```

그래도 초과 시 이미지를 별도 첨부로 분리한다.

---

## 용어 정의

| 용어 | 정의 |
|------|------|
| 기준 기간 | 보고서가 집계하는 날짜 범위 |
| 완료 이슈 | Jira 상태가 Done 또는 Closed인 이슈 |
| 빌드 성공률 | 성공 빌드 수 / 전체 빌드 수 × 100 |
| 재오픈률 | 재오픈된 이슈 수 / 전체 완료 이슈 수 × 100 |
| KPI | Key Performance Indicator, 핵심 성과 지표 |
| 이상치 | 이전 기간 대비 50% 이상 변화한 수치 |
| Blocker | 반드시 수정해야 최종 배포 가능한 검토 의견 |
