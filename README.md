# SneakWalk

**층간소음을 소재로, 살금살금 걸어 목표 지점에 도달하는 게임.**

Primitive Game-dev Team의 게임 기획 초안입니다. 현재 콘셉트와 챕터 아이디어를 정리하는 단계이며, 화면 구성과 세부 플레이 방식은 검토 중입니다.

## 핵심 콘셉트

- 플레이어는 위층 주민이 되어 집 안을 조심스럽게 이동합니다.
- 각 챕터에서 물 마시기, 라면 끓이기 등의 목표를 수행합니다.
- 살금살금 걷는 동작을 타이밍이나 음악의 리듬에 맞추는 방식을 검토합니다.

## 화면 구성

2D 화면을 기준으로 기획하며, 못 박기 리듬 게임과 비슷한 화면 구성을 검토합니다.

## 챕터 구상

아래 내용은 초기 아이디어이며, 구현 과정에서 세부 동선과 규칙을 구체화할 예정입니다.

### 챕터 1 — 내가 물 마시러 가기

**목표:** 내 방에서 나와 물을 마시고 다시 방으로 돌아오기.

**예상 동선:**

> 내 방 → 거실 → 부엌 → 물 마시기 → 부엌 → 거실 → 내 방

- 물을 마신 뒤 부엌 구간부터 진행 속도가 빨라지는 전개를 구상합니다.
- 돌아오는 길에 너무 느리게 이동하면 어머니에게 들키는 상황을 고려합니다.

### 챕터 2 — 아빠가 라면 끓여 먹기

**목표:** 아빠가 안방에서 나와 라면을 끓여 먹고 돌아가기.

**예상 동선:**

> 안방 → 복도 → 거실 → 부엌 → 라면 조리 → 거실 → 복도 → 안방

- 요리 과정 자체를 리듬 게임으로 구성하는 방안을 검토합니다.
- 조리 단계와 입력 방식 등 세부 내용은 추후 구체화합니다.

### 챕터 3 — 추후 기획

챕터 1과 2를 구현해 본 뒤, 이를 바탕으로 챕터 3의 아이디어를 정할 예정입니다.

## 이벤트 후보

- **떨어진 물건 줍기:** 이동 중 물건이 떨어지면 주워야 하는 상황.
- **강아지 짖음 막기:** 강아지가 짖지 않도록 막는 상황.
- **악기 연주:** 악기 연주를 활용한 이벤트. 구체적인 방식은 미정.

## 제작 작업 후보

2D 게임 제작을 위한 디자인·개발 작업 항목입니다.

| 분야 | 작업 항목 |
| --- | --- |
| 디자인 | 배경, 특수 이벤트에 필요한 사물, 2D 캐릭터, UI 구조 |
| 개발 | 2D 캐릭터 이동·애니메이션, 음악 선정 및 리듬에 맞춘 입력 구현, 게임 기본 기능 구현 |

## 앞으로 정할 내용

- 2D 화면의 세부 구성
- 살금살금 걷기의 입력 방식과 타이밍·리듬 규칙
- 주인공의 이동 목적, 목표 지점, 세부 동선
- 이벤트의 발생 조건과 플레이 방식
- 챕터 2의 요리 리듬 게임 세부 구성
- 챕터 1·2 구현 이후 챕터 3 기획

## 개발 환경

- **Unity:** 6.3 LTS (`6000.3.26f1`)
- **프로젝트:** 공식 2D 템플릿 기반, Built-in Render Pipeline
- **입력:** Unity Input System
- **시작 씬:** `Assets/Scenes/Main.unity`

### 프로젝트 열기

1. Unity Hub에서 `6000.3.26f1` Editor를 설치합니다.
2. Unity Hub의 **Add project from disk**로 이 저장소의 루트 폴더를 추가합니다. `Assets`, `Packages`, `ProjectSettings`가 있는 폴더입니다.
3. 프로젝트를 열고 패키지 설치와 에셋 임포트가 끝날 때까지 기다립니다.
4. `Assets/Scenes/Main.unity`를 엽니다.

`Assets/Scenes/Main.unity`가 시작 씬입니다. 챕터 1 플레이는 이 씬 하나에서 메뉴 → 게임 → 결과 순서로 진행됩니다.

### 폴더 구조

| 경로 | 용도 |
| --- | --- |
| [`Planning/`](Planning/README.md) | 기획 문서 |
| [`drawed/`](drawed/README.md) | 간단한 그림 기획·스케치 |
| `Assets/Art/Characters/` | 캐릭터 이미지·스프라이트 |
| `Assets/Art/Backgrounds/` | 배경 이미지 |
| `Assets/Art/Props/` | 사물·이벤트 이미지 |
| `Assets/Art/UI/` | UI 이미지 |
| `Assets/Audio/Music/` | 배경 음악·리듬 게임 음악 |
| `Assets/Audio/SFX/` | 효과음 |
| `Assets/Prefabs/` | 재사용할 게임 오브젝트 |
| `Assets/Scenes/` | Unity 씬 |
| `Assets/Scripts/` | C# 코드 |
| `Assets/Settings/` | 입력 등 에셋 형태의 설정 |
| `Packages/` | 패키지 목록과 버전 잠금 파일 |
| `ProjectSettings/` | Unity 프로젝트 공통 설정 |

### 협업 설정 및 검증

- Editor 기본 모드를 **2D**, 에셋 직렬화를 **Force Text**, 메타데이터 관리를 **Visible Meta Files**로 설정했습니다.
- 에셋을 추가하거나 이동할 때 `.meta` 파일도 함께 커밋합니다.
- `Library`, `Temp`, `Logs`, `UserSettings`, `Previews` 등 생성 파일은 Git에서 제외합니다.
- Unity 6000.3.26f1로 실제 임포트·컴파일·빌드를 확인했고, 패키지 버전을 이 Editor의 권장 버전으로 맞췄습니다.

## 실행 방법

1. Unity Hub에서 `6000.3.26f1` Editor를 설치합니다.
2. Unity Hub의 **Add project from disk**로 이 저장소의 루트 폴더를 추가합니다.
3. `Assets/Scenes/Main.unity`를 열고 Play를 누릅니다.
4. 명령줄로 빌드하려면:

```powershell
& "C:\Program Files\Unity\Hub\Editor\6000.3.26f1\Editor\Unity.exe" `
  -batchmode -nographics -quit -projectPath . `
  -buildTarget StandaloneWindows64 -buildWindows64Player .\Build\SneakWalk.exe `
  -logFile .\Logs\build.log
```

씬을 코드로 다시 만들려면 메뉴 **SneakWalk > Scene > Rebuild Main Scene**을 실행합니다. 아트를 추가한 뒤 한 번 돌리면 스프라이트 테이블이 갱신됩니다.

## 조작

| 입력 | 동작 |
| --- | --- |
| 클릭 / Space / Enter | 박자에 맞춰 걸음을 멈춘다 (판정 대상) |
| Space / Enter | 시작 화면에서 게임 시작 |
| R | 결과 화면에서 다시 하기 |
| M / Esc | 결과 화면에서 메뉴로 |

## 구현 상태

- **챕터 1 플레이 가능**: 내 방 → 거실 → 부엌 → 물 마시기 → 내 방. 규칙은 [docs/chapter1-design.md](docs/chapter1-design.md)에 정리했습니다.
- 검증: EditMode 테스트 10개, PlayMode 테스트 4개 통과. 자동 플레이 테스트가 챕터를 완주합니다(성공, 38.7초, 소음 0). Windows 빌드 성공.
- 아직 없음: 챕터 2, 음악 파일, 사운드 효과, 시각 박자 표시(요청에 따라 미구현), 설정 화면(자리만 있음).

## AI 생성 고지

이 저장소의 `ai/rhythm-ch1` 브랜치에 있는 챕터 1 구현은 **AI 에이전트가 생성한 코드**입니다.

- 대상: `Assets/Scripts/**`, `Assets/Tests/**`, `Assets/Editor/SneakWalkSceneBuilder.cs`, `docs/chapter1-design.md`, 이 README의 "실행 방법"·"조작"·"구현 상태"·"AI 생성 고지" 절, 그리고 `Packages/manifest.json`의 패키지 버전 수정
- 커밋 메시지에 `AI-Generated: true` 트레일러가 붙습니다.
- 생성 환경: Unity 6000.3.26f1, Windows 11
- 검증: 배치모드 임포트·컴파일, EditMode/PlayMode 테스트, 자동 플레이 완주, Windows 빌드, 방 합성 렌더
- 한계: 사람이 직접 조작해 확인한 손맛(입력 지연, 난이도)은 검증하지 않았습니다. 아트·기획 원본은 AI가 만들지 않았습니다.

사람의 리뷰 없이 병합하지 마세요. 특히 `GameConfig.cs`의 수치는 플레이 감각에 직결되므로 직접 만져 보고 조정하는 것을 권합니다.

