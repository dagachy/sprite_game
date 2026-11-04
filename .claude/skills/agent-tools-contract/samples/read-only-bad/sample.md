---
name: sample-auditor
description: Fixture — 감사기(auditor)인데 Write 도구 보유. 의도적 위반.
model: sonnet
tools: Read, Write, Bash
---

# sample-auditor

Fixture용 더미 감사기.
Verdict 기대값: **OVERPRIVILEGED**.
역할 신호 "auditor" (READ_ONLY) + tools에 Write → 과잉 권한.
