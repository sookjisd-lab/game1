# 그래픽 스타일 미결 사항 리뷰

> 일시: 2026-02-18
> 참여: designer, developer, reviewer
> 대상: 그래픽 스타일 리뷰에서 도출된 미결 사항 4건

---

## 미결 1: 환경 연출 로직 배치

### 검토 옵션
- 옵션 A: 각 스테이지 씬 내부에서 자체 처리
- 옵션 B: environment_manager (새 Autoload 매니저) 추가
- 옵션 C: 기존 매니저(audio_manager 등)에 합침

### Designer 의견: 옵션 A

- 스테이지별 환경이 질적으로 다름 (공통 로직이 아닌 고유 조합)
- 광장: 뒤틀린 오르골+핏빛 분수, 묘지: 안개+번개, 도서관: 날아다니는 책+잉크
- CLAUDE.md 8.8절 KISS: 스테이지 4~5개에서 매니저는 과도한 추상화
- base_stage.tscn에 CanvasModulate+기본 조명 포함, 각 스테이지가 상속+고유 노드 추가

### Developer 의견: 옵션 A + StageEnvironmentData Resource 분리

- 옵션 B는 씬 트리를 외부에서 조작하는 결합 발생 (Godot 설계 철학 충돌)
- 옵션 C는 SRP 명백히 위반
- StageEnvironmentData Resource에 환경 설정값 분리 → OCP 준수
- 구조:
  ```
  res://data/environments/town_square_env.tres
  res://data/environments/twisted_cemetery_env.tres
  ```
- StageEnvironment 노드가 _ready()에서 Resource 읽어 자동 설정

### Reviewer 결론

**스테이지 씬 내부 + StageEnvironmentData Resource 분리 채택. 매니저 신설 불필요.**
- 양측 합의, 충돌 없음. Designer "씬 내부" + Developer "Resource 분리"가 상호 보완.
- 근거: KISS(8.8절), OCP(8.4절)

---

## 미결 2: 거울 유령(24x24)과 엘리트(24x24) 크기 혼동

### 문제
10분 이후 동시 등장 시 둘 다 24x24로 혼동 가능.

### Designer 의견: 반투명(60~70%) + 밝은 아웃라인

- 반투명 = 유령+거울 반사 직관적 표현
- 엘리트(불투명+오라)와 즉시 구분
- 아웃라인 색: 밝은 하늘(#74D0F1) 또는 순백(#FFFFFF)
- modulate.a = 0.65 한 줄로 구현

### Developer 의견: 반투명(alpha 0.6) + UV flip 셰이더

- MultiMesh instance_color alpha로 투명도 조절 가능
- 거울 유령 전용 MultiMesh + 전용 ShaderMaterial
- UV.x 주기적 flip(0.5초 간격)으로 거울 반사 느낌
- 24x24 유지 (16x16 축소 시 시각적 정체성 소실)

### Reviewer 결론

**반투명(alpha 0.6) + 밝은 하늘색(#74D0F1) 아웃라인. 24x24 유지. UV flip은 풀 릴리즈 보류.**
- 반투명+아웃라인이 가장 직관적 차별화
- UV flip은 대칭 스프라이트에서 인지 어려움 → YAGNI로 보류
- 엘리트(불투명+자홍 오라)와 완전히 다른 시각적 카테고리

---

## 미결 3: 비표준 해상도 레터박스 디자인

### 문제
1366x768 등에서 integer 스케일링 시 레터박스(검은 띠) 발생.

### Designer 의견: 단계적 접근

- MVP: 짙은 보라(#2D1B3D) 단색 (프로젝트 설정 1줄)
- 폴리시: 넝쿨/가시 모티프 정적 테두리 이미지
- 동화책 테두리 = "동화책을 들여다보는" 메타포, 분위기 강화+차별화
- 단, 에셋 제작 비용으로 MVP에서는 단색 우선

### Developer 의견: 커스텀 색상 즉시 가능, 장식은 풀 릴리즈

- `default_clear_color` 변경으로 레터박스 색상 즉시 설정 가능
- 장식 이미지: SubViewport + SubViewportContainer 구조 필요 → 복잡도 중간
- 대부분 타겟(1080p/1440p)에서 레터박스 없음 → YAGNI
- MVP: #0D0715 (극짙은 보라-검정)

### Reviewer 결론

**MVP: #1A0F28(극짙은 보라) 단색. 장식은 풀 릴리즈.**
- Designer #2D1B3D는 게임 배경과 동일하여 경계 모호
- Developer #0D0715는 너무 어둡고 톤 이탈
- 절충: #1A0F28로 경계 명확 + 팔레트 톤 유지

---

## 미결 4: 데미지 숫자 비트맵 폰트와 본문 폰트 통일

### 문제
2중 폰트 전략에서 데미지 숫자(8x10px, 스프라이트 기반)의 스타일 위치가 불명확.

### Designer 의견: "가독성 기반 + 미세 불규칙"

- 표시 시간 0.3~0.5초 → 가독성이 절대 우선
- 그러나 너무 깔끔하면 동화책 분위기와 단절
- 각 숫자(0~9)의 두께/크기 미세(1px) 차이
- 2중 폰트 분류: 가독성 폰트 계열의 변형
- 8x10px에서 손글씨 스타일은 불가능 (획 굵기 변화 표현할 픽셀 부족)

### Developer 의견: BMFont + 에셋 불균일 + Tween

- Godot FontFile의 BMFont(.fnt) 임포트 사용 → Label 노드 기능 그대로 활용
- 같은 서체의 데미지 변형 버전 제작 (3색, 굵게, 드롭 셰도우)
- Theme 리소스로 노드 유형별 폰트 분리

에셋 레벨 불균일:
- 비트맵에서 각 숫자 baseline을 1px씩 불규칙 배치
- 획 두께도 미세 차이

코드 레벨 불균일:
- Tween 팝업 시 position에 randf_range(-0.5, 0.5) 오프셋
- 크리티컬 scale에 ±0.1 불균일
- 회전 randf_range(-3.0, 3.0) 도

가독성 보장:
- 1px 드롭 셰도우 내장
- 1080p에서 x6 스케일 시 실제 48x60px/digit

### Reviewer 결론

**가독성 폰트 계열 BMFont 변형 + 에셋 불규칙(baseline 1px) + Tween 흔들림(최대 1px) + Theme 리소스 분리.**
- 양측 완전 합의
- Theme 리소스 분리로 SRP/OCP 준수

---

## 최종 요약

| 미결 사항 | 결론 | GDD 반영 위치 |
|----------|------|-------------|
| 환경 연출 배치 | 스테이지 씬 내부 + StageEnvironmentData Resource | 부록: 환경 연출 구조 |
| 거울 유령 차별화 | 반투명(0.6) + #74D0F1 아웃라인, 24x24 유지 | 6.2절 + 6.3절 |
| 레터박스 | MVP: #1A0F28 단색, 풀 릴리즈: 동화책 테두리 | 부록: 해상도 상세 |
| 데미지 숫자 폰트 | BMFont 변형 + 불규칙 baseline + Tween + Theme | 4.5절 |
