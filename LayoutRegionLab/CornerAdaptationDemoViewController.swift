import UIKit

/// 실전 예제
///
/// 1) 타이틀 바: 첨부 스크린샷처럼 "My Title + 빨간 바"를 어떤 region 에 붙이느냐에 따라
///    iPad 창 모드의 윈도우 컨트롤(신호등)과 겹치는지/피하는지 비교
/// 2) 커스텀 바 (iOS 27.1+): bar(onEdge:extent:) + traitCollection.verticalBarEdge 로
///    시스템이 선호하는 edge에 내 바를 배치
final class CornerAdaptationDemoViewController: UIViewController {

    private enum TitleRegion: Int, CaseIterable {
        case safeArea, safeAreaH, safeAreaV, marginsH

        var label: String {
            switch self {
            case .safeArea: "safeArea()"
            case .safeAreaH: "safeArea(.horizontal)"
            case .safeAreaV: "safeArea(.vertical)"
            case .marginsH: "margins(.horizontal)"
            }
        }

        var region: UIView.LayoutRegion {
            switch self {
            case .safeArea: .safeArea()
            case .safeAreaH: .safeArea(cornerAdaptation: .horizontal)
            case .safeAreaV: .safeArea(cornerAdaptation: .vertical)
            case .marginsH: .margins(cornerAdaptation: .horizontal)
            }
        }
    }

    private enum BarPlacement: Int, CaseIterable {
        case auto, top, bottom, leading, trailing
        var label: String {
            switch self {
            case .auto: "자동(verticalBarEdge)"
            case .top: "top"
            case .bottom: "bottom"
            case .leading: "leading"
            case .trailing: "trailing"
            }
        }
    }

    // 타이틀 바
    private var titleRegion: TitleRegion = .safeAreaH
    private let guideOutline = UIView()
    private let titleBar = UIStackView()
    private var titleConstraints: [NSLayoutConstraint] = []

    // 커스텀 바
    private var barPlacement: BarPlacement = .auto
    private var barExtent: CGFloat = 64
    private let customBar = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
    private let customBarLabel = UILabel()
    private var barConstraints: [NSLayoutConstraint] = []
    private var installedBarKey: String?

    private let infoLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemYellow
        buildTitleBar()
        buildCustomBar()
        buildCard()
        applyTitleRegion()
    }

    // MARK: - Title bar

    private func buildTitleBar() {
        guideOutline.translatesAutoresizingMaskIntoConstraints = false
        guideOutline.isUserInteractionEnabled = false
        guideOutline.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.35)
        guideOutline.layer.borderColor = UIColor.systemOrange.cgColor
        guideOutline.layer.borderWidth = 2
        view.addSubview(guideOutline)

        let title = UILabel()
        title.text = "My Title"
        title.font = .systemFont(ofSize: 32, weight: .heavy)
        title.setContentHuggingPriority(.required, for: .horizontal)
        let filler = UIView()
        filler.backgroundColor = .systemRed

        titleBar.addArrangedSubview(title)
        titleBar.addArrangedSubview(filler)
        titleBar.spacing = 0
        titleBar.alignment = .fill
        titleBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleBar)
    }

    private func applyTitleRegion() {
        NSLayoutConstraint.deactivate(titleConstraints)
        let g = view.layoutGuide(for: titleRegion.region)
        titleConstraints = [
            guideOutline.topAnchor.constraint(equalTo: g.topAnchor),
            guideOutline.bottomAnchor.constraint(equalTo: g.bottomAnchor),
            guideOutline.leadingAnchor.constraint(equalTo: g.leadingAnchor),
            guideOutline.trailingAnchor.constraint(equalTo: g.trailingAnchor),
            titleBar.topAnchor.constraint(equalTo: g.topAnchor),
            titleBar.leadingAnchor.constraint(equalTo: g.leadingAnchor),
            titleBar.trailingAnchor.constraint(equalTo: g.trailingAnchor),
            titleBar.heightAnchor.constraint(equalToConstant: 40),
        ]
        NSLayoutConstraint.activate(titleConstraints)
        UIView.animate(withDuration: 0.3) { self.view.layoutIfNeeded() }
    }

    // MARK: - Custom bar (iOS 27.1+)

    private func buildCustomBar() {
        customBar.translatesAutoresizingMaskIntoConstraints = false
        customBar.layer.borderColor = UIColor.systemBlue.cgColor
        customBar.layer.borderWidth = 2
        customBarLabel.font = .monospacedSystemFont(ofSize: 11, weight: .semibold)
        customBarLabel.numberOfLines = 0
        customBarLabel.textAlignment = .center
        customBarLabel.translatesAutoresizingMaskIntoConstraints = false
        customBar.contentView.addSubview(customBarLabel)
        NSLayoutConstraint.activate([
            customBarLabel.centerXAnchor.constraint(equalTo: customBar.contentView.centerXAnchor),
            customBarLabel.centerYAnchor.constraint(equalTo: customBar.contentView.centerYAnchor),
            customBarLabel.widthAnchor.constraint(lessThanOrEqualTo: customBar.contentView.widthAnchor, constant: -8),
        ])
        view.addSubview(customBar)
        customBar.isHidden = true
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        installCustomBarIfNeeded()
    }

    /// verticalBarEdge 는 회전/창 크기 변경으로 바뀔 수 있으므로 레이아웃 때마다 확인
    private func installCustomBarIfNeeded() {
        guard #available(iOS 27.1, *) else { return }

        let region: UIView.LayoutRegion
        let code: String
        switch resolvedPlacement() {
        case .top:
            region = .bar(onEdge: UIRectEdge.top, extent: barExtent)
            code = ".bar(onEdge: UIRectEdge.top, extent: \(Int(barExtent)))"
        case .bottom:
            region = .bar(onEdge: UIRectEdge.bottom, extent: barExtent)
            code = ".bar(onEdge: UIRectEdge.bottom, extent: \(Int(barExtent)))"
        case .leading:
            region = .bar(onEdge: NSDirectionalRectEdge.leading, extent: barExtent)
            code = ".bar(onEdge: .leading, extent: \(Int(barExtent)))"
        default:
            region = .bar(onEdge: NSDirectionalRectEdge.trailing, extent: barExtent)
            code = ".bar(onEdge: .trailing, extent: \(Int(barExtent)))"
        }

        guard installedBarKey != code else { return }
        installedBarKey = code

        NSLayoutConstraint.deactivate(barConstraints)
        let g = view.layoutGuide(for: region)
        barConstraints = [
            customBar.topAnchor.constraint(equalTo: g.topAnchor),
            customBar.bottomAnchor.constraint(equalTo: g.bottomAnchor),
            customBar.leadingAnchor.constraint(equalTo: g.leadingAnchor),
            customBar.trailingAnchor.constraint(equalTo: g.trailingAnchor),
        ]
        NSLayoutConstraint.activate(barConstraints)
        customBar.isHidden = false
        customBarLabel.text = "Custom Bar\n\(code)"
    }

    @available(iOS 27.1, *)
    private func resolvedPlacement() -> BarPlacement {
        guard barPlacement == .auto else { return barPlacement }
        switch traitCollection.verticalBarEdge {
        case .leading: return .leading
        case .trailing: return .trailing
        default: return .bottom   // 세로 바를 쓰지 않는 환경 → 일반적인 하단 바
        }
    }

    // MARK: - Center card

    private func buildCard() {
        let card = UIStackView()
        card.axis = .vertical
        card.spacing = 12
        card.isLayoutMarginsRelativeArrangement = true
        card.directionalLayoutMargins = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
        card.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.85)
        card.layer.cornerRadius = 20
        card.layer.cornerCurve = .continuous
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)

        let h1 = UILabel()
        h1.text = "타이틀 바를 붙일 region"
        h1.font = .systemFont(ofSize: 13, weight: .bold)
        let titleSeg = UISegmentedControl(items: TitleRegion.allCases.map(\.label))
        titleSeg.selectedSegmentIndex = titleRegion.rawValue
        titleSeg.addAction(UIAction { [weak self, weak titleSeg] _ in
            guard let self, let i = titleSeg?.selectedSegmentIndex,
                  let r = TitleRegion(rawValue: i) else { return }
            self.titleRegion = r
            self.applyTitleRegion()
            self.view.setNeedsLayout()
        }, for: .valueChanged)

        let h2 = UILabel()
        h2.text = "커스텀 바 위치 (bar(onEdge:extent:), iOS 27.1+)"
        h2.font = .systemFont(ofSize: 13, weight: .bold)
        let barSeg = UISegmentedControl(items: BarPlacement.allCases.map(\.label))
        barSeg.selectedSegmentIndex = 0
        barSeg.addAction(UIAction { [weak self, weak barSeg] _ in
            guard let self, let i = barSeg?.selectedSegmentIndex,
                  let p = BarPlacement(rawValue: i) else { return }
            self.barPlacement = p
            self.view.setNeedsLayout()
        }, for: .valueChanged)

        let slider = UISlider()
        slider.minimumValue = 20
        slider.maximumValue = 160
        slider.value = Float(barExtent)
        slider.addAction(UIAction { [weak self, weak slider] _ in
            guard let self, let slider else { return }
            self.barExtent = CGFloat(slider.value.rounded())
            self.view.setNeedsLayout()
        }, for: .valueChanged)

        if #unavailable(iOS 27.1) {
            barSeg.isEnabled = false
            slider.isEnabled = false
        }

        infoLabel.numberOfLines = 0
        infoLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        infoLabel.textColor = .secondaryLabel

        let close = UIButton(configuration: .filled())
        close.configuration?.title = "닫기"
        close.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .primaryActionTriggered)

        [h1, titleSeg, h2, barSeg, slider, infoLabel, close].forEach(card.addArrangedSubview)

        let w = card.widthAnchor.constraint(equalToConstant: 560)
        w.priority = .defaultHigh
        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            w,
            card.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -32),
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let r = titleRegion.region
        var lines = [
            "선택: \(titleRegion.label)",
            InsetText.edge(view.edgeInsets(for: r)),
            InsetText.directional(view.directionalEdgeInsets(for: r)),
            "",
            "참고 safeAreaInsets  T \(view.safeAreaInsets.top.fmt)  L \(view.safeAreaInsets.left.fmt)  B \(view.safeAreaInsets.bottom.fmt)  R \(view.safeAreaInsets.right.fmt)",
        ]
        if #available(iOS 27.1, *) {
            let edge: String
            switch traitCollection.verticalBarEdge {
            case .leading: edge = ".leading"
            case .trailing: edge = ".trailing"
            case .unspecified: edge = ".unspecified → bottom 사용"
            @unknown default: edge = "unknown"
            }
            lines.append("verticalBarEdge = \(edge)")
            lines.append("customBar.frame = \(InsetText.rect(customBar.frame).replacingOccurrences(of: "guide.frame     ", with: ""))")
        } else {
            lines.append("커스텀 바 데모는 iOS 27.1 이상에서 동작")
        }
        let text = lines.joined(separator: "\n")
        if infoLabel.text != text { infoLabel.text = text }
    }
}
