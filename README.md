# LayoutRegion Lab

`UIView.LayoutRegion` API들이 **실제로 어느 영역을 가리키는지** 색 박스로 겹쳐 그려서 비교하는 UIKit 예제입니다.

- 요구사항: Xcode 27.1 (iOS 27.1 SDK), 배포 타깃 iOS 26.0
- `bar(onEdge:)`, `bar(onEdge:extent:)`, `traitCollection.verticalBarEdge`는 iOS 27.1+라서 `#available(iOS 27.1, *)`로 막아 두었습니다. 26.x 기기에서는 해당 행이 비활성화됩니다.
- 열기: `LayoutRegionLab.xcodeproj` → Signing에서 Team 선택 → 실행

## 화면 1 — 플레이그라운드

| 보이는 것 | 의미 |
|---|---|
| 시안 배경 | `view.bounds` 전체 |
| 각 색 박스 | `view.layoutGuide(for: region).layoutFrame` |
| 패널 숫자 `edgeInsets` | `view.edgeInsets(for: region)` (left/right, 물리 방향) |
| 패널 숫자 `directional` | `view.directionalEdgeInsets(for: region)` (leading/trailing, 논리 방향) |

패널 헤더를 드래그하면 패널을 옮길 수 있고, ⌃ 버튼으로 접을 수 있습니다.

### 꼭 해볼 것

1. **iPad 창 모드 (Windowed Apps / Stage Manager)**: 창 좌상단 신호등 버튼이 생기면
   - `safeArea(nil)`는 신호등과 겹침
   - `safeArea(.horizontal)`는 **leading 인셋**이 커져서 신호등 오른쪽부터 시작 (첨부 스크린샷의 `leading: 66`)
   - `safeArea(.vertical)`는 **top 인셋**이 커져서 신호등 아래부터 시작
2. 창 크기를 줄여 보기: `readableContent`의 폭 제한이 어떻게 바뀌는지 확인
3. **RTL 강제** 토글: `UIRectEdge.left`는 그대로, `NSDirectionalRectEdge.leading`은 반대편으로 뒤집힘. `edgeInsets` 값과 `directional` 값이 서로 바뀌는 것도 확인
4. **extent 슬라이더**: `bar(onEdge:)`(시스템 두께) 대 `bar(onEdge:extent:)`(직접 지정) 비교
5. iPhone 가로 회전 → `verticalBarEdge`가 `.unspecified`에서 다른 값으로 바뀌는지 확인

## 화면 2 — 실전 예제 (패널의 파란 버튼)

- 첨부 스크린샷과 같은 "My Title + 빨간 바" 타이틀 바를 4가지 region에 바꿔 붙여 봅니다 (주황 박스 = 선택한 가이드).
- 커스텀 바: `traitCollection.verticalBarEdge`가 `.leading`/`.trailing`이면 그 edge에, `.unspecified`이면 bottom에 `bar(onEdge:extent:)`로 배치합니다. Apple 포럼에서 프레임워크 엔지니어가 커스텀 세로 바에 권한 조합입니다.

## 파일 구성

- `RegionCatalog.swift`: 비교할 region 목록과 설명 (여기에 추가하면 화면에 바로 반영)
- `RegionOverlayView.swift`: `layoutGuide(for:)`에 네 변을 붙이는 색 박스
- `PlaygroundViewController.swift`: 오버레이 및 수치 표시
- `ControlPanelView.swift`: 떠 있는 패널
- `CornerAdaptationDemoViewController.swift`: 실전 예제
