---
name: sample-violations-router
description: menu-pattern-auditor 자가 검증용 violations 샘플. 라우터 비대·본문 상세·cross-ref를 의도적으로 포함. 임의 샘플명으로 실제 트리거 방지.
---

# violations-router

라우팅과 본문이 섞여 있는 안티패턴 라우터.

## 라우팅
- 알파 관련이면 `references/alpha.md`
- 베타 관련이면 `references/beta.md`

## 알파 도메인 상세

라우터 안에 도메인 본문이 들어있는 안티패턴.

### 알파 템플릿 A1

알파 도메인에서는 아래 템플릿을 사용한다. 라우터에 들어오면 안 되는 상세.

```sql
SELECT alpha_id, alpha_value
FROM alpha_table
WHERE alpha_status = 'active';
```

### 알파 템플릿 A2

```sql
UPDATE alpha_table
SET alpha_value = alpha_value + 1
WHERE alpha_id = ?;
```

### 알파 주의사항

본문 상세가 라우터에 섞이면 라우터가 비대해지고 메뉴판 원칙이 깨진다.

## 베타 도메인 상세

### 베타 템플릿 B1

```yaml
beta:
  mode: strict
  retry: 3
```

### 베타 템플릿 B2

```yaml
beta_bulk:
  batch_size: 100
```

### 베타 주의사항

위 네 가지 안티패턴이 동시에 발현되는 샘플.
