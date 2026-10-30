import UIKit

/// 모든 LayoutRegion 을 한 화면에 겹쳐 그리는 플레이그라운드.
///
/// - 배경색(시안) = view.bounds 전체
/// - 각 색 박스 = view.layoutGuide(for: region) 의 프레임
/// - 패널의 숫자 = view.edgeInsets(for:) / view.directionalEdgeInsets(for:)
///
/// iPad에서 Stage Manager / 창 모드로 창 크기를 바꿔보거나,
/// iPhone을 가로로 돌려보면서 각 영역이 어떻게 달라지는지 보면 된다.
final class PlaygroundViewController: UIViewController {

    private let specs = RegionCatalog.all
    private var overlays: [String: RegionOverlayView] = [:]
    private var enabled: Set<String> = []
    private var available: Set<String> = []
    private var extent: CGFloat = 60

    private let panel = ControlPanelView()
    private var panelX: NSLayoutConstraint!
    private var panelY: NSLayoutConstraint!
    private var panStart = CGPoint.zero

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.0, green: 0.72, blue: 0.90, alpha: 1)

        let boundsTag = UILabel()
        boundsTag.text = "  배경(시안) = view.bounds  "
        boundsTag.font = .systemFont(ofSize: 11, weight: .semibold)
        boundsTag.textColor = .white
        boundsTag.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        boundsTag.layer.cornerRadius = 6
        boundsTag.clipsToBounds = true
        boundsTag.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(boundsTag)
        NSLayoutConstraint.activate([
            boundsTag.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            boundsTag.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -2),
        ])

        // 오버레이 생성
        for (i, spec) in specs.enumerated() {
            let o = RegionOverlayView(spec: spec, slot: i)
            view.addSubview(o)
            overlays[spec.id] = o
            if o.attach(to: view, extent: extent) {
                available.insert(spec.id)
                if spec.defaultOn { enabled.insert(spec.id) }
            }
            o.isHidden = !enabled.contains(spec.id)
        }

        setUpPanel()
    }

    // MARK: - Panel

    private func setUpPanel() {
        view.addSubview(panel)
        panel.configure(specs: specs, enabled: enabled, available: available, extent: extent)

        // 패널은 의도적으로 bounds 기준(가이드 X)으로 배치 → 측정 대상에 영향 없음
        panelX = panel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        panelY = panel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        let preferredWidth = panel.widthAnchor.constraint(equalToConstant: 440)
        preferredWidth.priority = .defaultHigh
        NSLayoutConstraint.activate([
            panelX, panelY, preferredWidth,
            panel.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -24),
            panel.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.72),
        ])

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panel.header.addGestureRecognizer(pan)

        panel.onToggle = { [weak self] id, on in
            guard let self else { return }
            if on { self.enabled.insert(id) } else { self.enabled.remove(id) }
            self.overlays[id]?.isHidden = !on
        }
        panel.onSetAll = { [weak self] on in
            guard let self else { return }
            self.enabled = on ? self.available : []
            for (id, o) in self.overlays { o.isHidden = !self.enabled.contains(id) }
        }
        panel.onExtentChange = { [weak self] value in
            guard let self else { return }
            self.extent = value
            // extent 는 region 값 자체에 들어가므로 새 region 으로 가이드를 다시 얻어야 함
            for spec in self.specs where spec.usesExtent {
                self.overlays[spec.id]?.attach(to: self.view, extent: value)
            }
            self.view.setNeedsLayout()
        }
        panel.onRTLChange = { [weak self] on in
            guard let self else { return }
            if on {
                self.traitOverrides.layoutDirection = .rightToLeft
            } else {
                self.traitOverrides.remove(UITraitLayoutDirection.self)
            }
            self.view.setNeedsLayout()
        }
        panel.onOpenDemo = { [weak self] in
            let demo = CornerAdaptationDemoViewController()
            demo.modalPresentationStyle = .fullScreen
            self?.present(demo, animated: true)
        }
    }

    @objc private func handlePan(_ g: UIPanGestureRecognizer) {
        switch g.state {
        case .began:
            panStart = CGPoint(x: panelX.constant, y: panelY.constant)
        case .changed:
            let t = g.translation(in: view)
            panelX.constant = panStart.x + t.x
            panelY.constant = panStart.y + t.y
        default:
            break
        }
    }

    // MARK: - Readouts

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        refreshReadouts()
    }

    private func refreshReadouts() {
        panel.updateEnvironment(environmentText())

        for spec in specs {
            guard let region = spec.make(extent) else {
                panel.updateReadout(id: spec.id, text: "—")
                continue
            }
            var lines = [
                InsetText.edge(view.edgeInsets(for: region)),
                InsetText.directional(view.directionalEdgeInsets(for: region)),
            ]
            if let g = overlays[spec.id]?.guide {
                lines.append(InsetText.rect(g.layoutFrame))
            }
            panel.updateReadout(id: spec.id, text: lines.joined(separator: "\n"))
        }
    }

    private func environmentText() -> String {
        let b = view.bounds
        let s = view.safeAreaInsets
        let m = view.directionalLayoutMargins
        let tc = traitCollection
        var lines = [
            "bounds          \(b.width.fmt) × \(b.height.fmt)",
            "safeAreaInsets  T \(s.top.fmt)  L \(s.left.fmt)  B \(s.bottom.fmt)  R \(s.right.fmt)",
            "layoutMargins   T \(m.top.fmt)  Ld \(m.leading.fmt)  B \(m.bottom.fmt)  Tr \(m.trailing.fmt)",
            "sizeClass       H \(name(tc.horizontalSizeClass))  V \(name(tc.verticalSizeClass))",
            "layoutDirection \(tc.layoutDirection == .rightToLeft ? "RTL" : "LTR")",
        ]
        if #available(iOS 27.1, *) {
            let edge: String
            switch tc.verticalBarEdge {
            case .leading: edge = ".leading"
            case .trailing: edge = ".trailing"
            case .unspecified: edge = ".unspecified"
            @unknown default: edge = "unknown"
            }
            lines.append("verticalBarEdge \(edge)")
        } else {
            lines.append("verticalBarEdge (iOS 27.1+)")
        }
        return lines.joined(separator: "\n")
    }

    private func name(_ c: UIUserInterfaceSizeClass) -> String {
        switch c {
        case .compact: "compact"
        case .regular: "regular"
        default: "unspecified"
        }
    }
}
