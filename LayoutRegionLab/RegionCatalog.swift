import UIKit

/// 화면에 그려볼 LayoutRegion 한 개에 대한 정의.
struct RegionSpec {
    let id: String
    let group: String
    /// 화면에 표시할 코드 표현
    let code: String
    /// 무엇을 보면 되는지 힌트
    let note: String
    let color: UIColor
    let defaultOn: Bool
    /// extent 슬라이더 값을 쓰는지
    let usesExtent: Bool
    /// 현재 OS에서 쓸 수 없으면 nil (bar 계열은 iOS 27.1+)
    let make: (_ extent: CGFloat) -> UIView.LayoutRegion?
}

enum RegionCatalog {

    static let groups: [String] = [
        "safeArea(cornerAdaptation:)",
        "margins(cornerAdaptation:)",
        "readableContent(cornerAdaptation:)",
        "bar(onEdge:extent:)  — iOS 27.1+",
    ]

    static let all: [RegionSpec] = safeAreaSpecs + marginsSpecs + readableSpecs + barSpecs

    // MARK: - cornerAdaptation 3종 (nil / .horizontal / .vertical)

    private typealias Axis = UIView.LayoutRegion.AdaptivityAxis

    private static func adaptive(
        group: String,
        name: String,
        colors: [UIColor],
        notes: [String],
        defaultOn: [Bool],
        factory: @escaping (Axis?) -> UIView.LayoutRegion
    ) -> [RegionSpec] {
        let axes: [(label: String, axis: Axis?)] = [
            ("nil", nil),
            (".horizontal", .horizontal),
            (".vertical", .vertical),
        ]
        return axes.enumerated().map { index, item in
            RegionSpec(
                id: "\(name)-\(item.label)",
                group: group,
                code: ".\(name)(cornerAdaptation: \(item.label))",
                note: notes[index],
                color: colors[index],
                defaultOn: defaultOn[index],
                usesExtent: false,
                make: { _ in factory(item.axis) }
            )
        }
    }

    private static let safeAreaSpecs = adaptive(
        group: groups[0],
        name: "safeArea",
        colors: [Palette.green, Palette.red, Palette.blue],
        notes: [
            "기존 safeAreaLayoutGuide / safeAreaInsets 와 같은 영역. iPad 창 모드에서 좌상단 윈도우 컨트롤(신호등)과 겹칠 수 있음",
            "모서리의 윈도우 컨트롤을 '가로로' 피함 → 해당 줄의 leading/trailing 인셋이 커짐 (타이틀 바처럼 가로로 긴 UI용)",
            "모서리의 윈도우 컨트롤을 '세로로' 피함 → top/bottom 인셋이 커짐 (사이드바처럼 세로로 긴 UI용)",
        ],
        defaultOn: [true, true, false],
        factory: { .safeArea(cornerAdaptation: $0) }
    )

    private static let marginsSpecs = adaptive(
        group: groups[1],
        name: "margins",
        colors: [Palette.orange, Palette.violet, Palette.brown],
        notes: [
            "기존 layoutMarginsGuide 와 같은 영역 (safe area + layoutMargins)",
            "margins 기준에서 윈도우 컨트롤을 가로로 피함",
            "margins 기준에서 윈도우 컨트롤을 세로로 피함",
        ],
        defaultOn: [false, false, false],
        factory: { .margins(cornerAdaptation: $0) }
    )

    private static let readableSpecs = adaptive(
        group: groups[2],
        name: "readableContent",
        colors: [Palette.yellow, Palette.navy, Palette.pink],
        notes: [
            "기존 readableContentGuide 와 같은 영역 (긴 텍스트 읽기용 최대 폭)",
            "readableContent 기준에서 윈도우 컨트롤을 가로로 피함 (폭이 넓은 창에선 차이가 안 보일 수 있음)",
            "readableContent 기준에서 윈도우 컨트롤을 세로로 피함",
        ],
        defaultOn: [false, false, false],
        factory: { .readableContent(cornerAdaptation: $0) }
    )

    // MARK: - bar (iOS 27.1+)

    private static func bar(
        id: String, code: String, note: String, color: UIColor, usesExtent: Bool,
        make: @escaping (CGFloat) -> UIView.LayoutRegion?
    ) -> RegionSpec {
        RegionSpec(id: id, group: groups[3], code: code, note: note, color: color,
                   defaultOn: false, usesExtent: usesExtent, make: make)
    }

    // 참고: extent 없는 bar(onEdge:) 는 현재 SDK(27.1)에 없어서 제외함
    private static let barSpecs: [RegionSpec] = [
        bar(id: "bar-top-extent", code: ".bar(onEdge: UIRectEdge.top, extent: ⟨슬라이더⟩)",
            note: "top edge용 바 영역. 상태바/윈도우 컨트롤과의 관계를 확인",
            color: Palette.black, usesExtent: true) { extent in
            if #available(iOS 27.1, *) { return UIView.LayoutRegion.bar(onEdge: UIRectEdge.top, extent: extent) }
            return nil
        },
        bar(id: "bar-bottom-extent", code: ".bar(onEdge: UIRectEdge.bottom, extent: ⟨슬라이더⟩)",
            note: "bottom edge용 바 영역. 홈 인디케이터 영역과의 관계를 확인",
            color: Palette.slate, usesExtent: true) { extent in
            if #available(iOS 27.1, *) { return UIView.LayoutRegion.bar(onEdge: UIRectEdge.bottom, extent: extent) }
            return nil
        },
        bar(id: "bar-left-extent", code: ".bar(onEdge: UIRectEdge.left, extent: ⟨슬라이더⟩)",
            note: "물리적 left. RTL을 켜도 왼쪽에 그대로 있어야 함 (UIRectEdge)",
            color: Palette.olive, usesExtent: true) { extent in
            if #available(iOS 27.1, *) { return UIView.LayoutRegion.bar(onEdge: UIRectEdge.left, extent: extent) }
            return nil
        },
        bar(id: "bar-leading-extent", code: ".bar(onEdge: NSDirectionalRectEdge.leading, extent: ⟨슬라이더⟩)",
            note: "논리적 leading. RTL을 켜면 반대편으로 뒤집힘 (NSDirectionalRectEdge)",
            color: Palette.deepTeal, usesExtent: true) { extent in
            if #available(iOS 27.1, *) { return UIView.LayoutRegion.bar(onEdge: NSDirectionalRectEdge.leading, extent: extent) }
            return nil
        },
        bar(id: "bar-trailing-extent", code: ".bar(onEdge: NSDirectionalRectEdge.trailing, extent: ⟨슬라이더⟩)",
            note: "논리적 trailing + 직접 지정한 두께",
            color: Palette.lime, usesExtent: true) { extent in
            if #available(iOS 27.1, *) { return UIView.LayoutRegion.bar(onEdge: NSDirectionalRectEdge.trailing, extent: extent) }
            return nil
        },
    ]
}

// MARK: - 팔레트 (서로 확실히 구분되는 14색, 배경 시안과도 겹치지 않게)

enum Palette {
    static let green    = UIColor(hex: 0x00C853)
    static let red      = UIColor(hex: 0xD50000)
    static let blue     = UIColor(hex: 0x2962FF)
    static let orange   = UIColor(hex: 0xFF6D00)
    static let violet   = UIColor(hex: 0xAA00FF)
    static let brown    = UIColor(hex: 0x6D4C41)
    static let yellow   = UIColor(hex: 0xFFD600)
    static let navy     = UIColor(hex: 0x1A237E)
    static let pink     = UIColor(hex: 0xFF4FA3)
    static let black    = UIColor(hex: 0x111111)
    static let slate    = UIColor(hex: 0x607D8B)
    static let olive    = UIColor(hex: 0x827717)
    static let deepTeal = UIColor(hex: 0x004D40)
    static let lime     = UIColor(hex: 0xC6FF00)
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: 1)
    }

    /// 밝은 색(노랑/라임) 위에는 검은 글씨가 읽히도록
    var readableTextColor: UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance > 0.6 ? .black : .white
    }
}

// MARK: - 포맷 헬퍼

extension CGFloat {
    var fmt: String { String(format: "%.1f", Double(self)) }
}

enum InsetText {
    static func edge(_ e: UIEdgeInsets) -> String {
        "edgeInsets      T \(e.top.fmt)  L \(e.left.fmt)  B \(e.bottom.fmt)  R \(e.right.fmt)"
    }
    static func directional(_ d: NSDirectionalEdgeInsets) -> String {
        "directional     T \(d.top.fmt)  Ld \(d.leading.fmt)  B \(d.bottom.fmt)  Tr \(d.trailing.fmt)"
    }
    static func rect(_ r: CGRect) -> String {
        "guide.frame     x \(r.minX.fmt)  y \(r.minY.fmt)  w \(r.width.fmt)  h \(r.height.fmt)"
    }
}
