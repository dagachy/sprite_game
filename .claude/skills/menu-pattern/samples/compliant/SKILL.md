---
name: sample-compliant-router
description: menu-pattern-auditor 자가 검증용 compliant 샘플. 임의 샘플명으로 실제 트리거 방지. 05/domain-references의 sql-query를 중립 도메인(A/B)으로 변형한 것.
---

# compliant-router (메뉴판 — 라우터만)

도메인 본문 없이 조건부 링크만 둔다 (메뉴판 원칙).

## 라우팅
- 도메인 A 관련 요청이면 `references/domain-a.md`
- 도메인 B 관련 요청이면 `references/domain-b.md`

단순 처리는 직접 수행. 도메인 템플릿이 필요할 때만 해당 references 로드.
