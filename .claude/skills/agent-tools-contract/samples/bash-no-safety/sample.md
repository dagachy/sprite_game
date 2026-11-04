---
name: sample-builder
description: Fixture 더미 에이전트 - 범용 빌더 역할. Bash 셸 명령을 실행한다.
model: sonnet
tools: Read, Write, Bash
---

# sample-builder

Fixture 더미 빌더 에이전트.

## 역할

빌드 파이프라인을 조립하고 결과물을 출력 디렉토리에 쓴다.
입력 파일을 읽어 변환하여 출력을 생성한다.

## 입출력

- 입력: 소스 디렉토리 경로
- 출력: 빌드 산출물 디렉토리
