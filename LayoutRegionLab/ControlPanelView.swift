import UIKit

/// 가운데 떠 있는 컨트롤 패널. 헤더를 드래그하면 이동, ⌃ 버튼으로 접기.
final class ControlPanelView: UIView {

    var onToggle: ((String, Bool) -> Void)?
    var onSetAll: ((Bool) -> Void)?
    var onExtentChange: ((CGFloat) -> Void)?
    var onRTLChange: ((Bool) -> Void)?
    var onOpenDemo: (() -> Void)?

    let header = UIStackView()
    private let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
    private let outer = UIStackView()
    private let scroll = UIScrollView()
    private let content = UIStackView()
    private let envLabel = UILabel()
    private let extentLabel = UILabel()
    private let extentSlider = UISlider()
    private let rtlSwitch = UISwitch()
    private let collapseButton = UIButton(type: .system)
    private var switches: [String: UISwitch] = [:]
    private var readouts: [String: UILabel] = [:]
    private var collapsed = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.25
        layer.shadowRadius = 20
        layer.shadowOffset = CGSize(width: 0, height: 8)

        blur.translatesAutoresizingMaskIntoConstraints = false
        blur.layer.cornerRadius = 22
        blur.layer.cornerCurve = .continuous
        blur.clipsToBounds = true
        addSubview(blur)

        outer.axis = .vertical
        outer.spacing = 0
        outer.translatesAutoresizingMaskIntoConstraints = false
        blur.contentView.addSubview(outer)

        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: topAnchor),
            blur.bottomAnchor.constraint(equalTo: bottomAnchor),
            blur.leadingAnchor.constraint(equalTo: leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: trailingAnchor),
            outer.topAnchor.constraint(equalTo: blur.contentView.topAnchor),
            outer.bottomAnchor.constraint(equalTo: blur.contentView.bottomAnchor),
            outer.leadingAnchor.constraint(equalTo: blur.contentView.leadingAnchor),
            outer.trailingAnchor.constraint(equalTo: blur.contentView.trailingAnchor),
        ])

        buildHeader()
        buildScroll()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Header

    private func buildHeader() {
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 8
        header.isLayoutMarginsRelativeArrangement = true
        header.directionalLayoutMargins = .init(top: 12, leading: 16, bottom: 12, trailing: 12)

        let grip = UIImageView(image: UIImage(systemName: "line.3.horizontal"))
        grip.tintColor = .tertiaryLabel
        let title = UILabel()
        title.text = "LayoutRegion Lab"
        title.font = .systemFont(ofSize: 17, weight: .bold)

        let allOff = UIButton(configuration: .gray())
        allOff.configuration?.title = "모두 끄기"
        allOff.configuration?.buttonSize = .small
        allOff.addAction(UIAction { [weak self] _ in self?.setAll(false) }, for: .primaryActionTriggered)

        var cc = UIButton.Configuration.plain()
        cc.image = UIImage(systemName: "chevron.up")
        collapseButton.configuration = cc
        collapseButton.addAction(UIAction { [weak self] _ in self?.toggleCollapsed() }, for: .primaryActionTriggered)

        let spacer = UIView()
        header.addArrangedSubview(grip)
        header.addArrangedSubview(title)
        header.addArrangedSubview(spacer)
        header.addArrangedSubview(allOff)
        header.addArrangedSubview(collapseButton)
        title.setContentHuggingPriority(.required, for: .horizontal)
        outer.addArrangedSubview(header)
    }

    private func toggleCollapsed() {
        collapsed.toggle()
        collapseButton.configuration?.image = UIImage(systemName: collapsed ? "chevron.down" : "chevron.up")
        UIView.animate(withDuration: 0.25) {
            self.scroll.isHidden = self.collapsed
            self.superview?.layoutIfNeeded()
        }
    }

    // MARK: - Body

    private func buildScroll() {
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true
        outer.addArrangedSubview(scroll)

        content.axis = .vertical
        content.spacing = 10
        content.translatesAutoresizingMaskIntoConstraints = false
        content.isLayoutMarginsRelativeArrangement = true
        content.directionalLayoutMargins = .init(top: 4, leading: 16, bottom: 18, trailing: 16)
        scroll.addSubview(content)

        // 내용 높이만큼 늘어나되, 패널 최대 높이 제약에 걸리면 스크롤
        let fit = scroll.heightAnchor.constraint(equalTo: content.heightAnchor)
        fit.priority = .defaultLow
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            content.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),
            fit,
        ])

        // 환경 정보
        content.addArrangedSubview(sectionTitle("현재 뷰 환경"))
        envLabel.numberOfLines = 0
        envLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        envLabel.textColor = .secondaryLabel
        content.addArrangedSubview(envLabel)

        // 컨트롤
        content.addArrangedSubview(sectionTitle("컨트롤"))
        extentLabel.font = .monospacedSystemFont(ofSize: 12, weight: .medium)
        extentSlider.minimumValue = 0
        extentSlider.maximumValue = 200
        extentSlider.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let v = CGFloat(self.extentSlider.value.rounded())
            self.extentLabel.text = "extent: \(Int(v))"
            self.onExtentChange?(v)
        }, for: .valueChanged)
        content.addArrangedSubview(row(extentLabel, extentSlider, ratio: 0.32))

        let rtlLabel = UILabel()
        rtlLabel.text = "RTL 강제 (leading ↔ left 비교)"
        rtlLabel.font = .systemFont(ofSize: 13)
        rtlSwitch.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.onRTLChange?(self.rtlSwitch.isOn)
        }, for: .valueChanged)
        content.addArrangedSubview(row(rtlLabel, rtlSwitch, ratio: nil))

        let demo = UIButton(configuration: .filled())
        demo.configuration?.title = "실전 예제: 타이틀 바 · 커스텀 바 열기"
        demo.configuration?.image = UIImage(systemName: "rectangle.inset.topleft.filled")
        demo.configuration?.imagePadding = 6
        demo.addAction(UIAction { [weak self] _ in self?.onOpenDemo?() }, for: .primaryActionTriggered)
        content.addArrangedSubview(demo)
    }

    func configure(specs: [RegionSpec], enabled: Set<String>, available: Set<String>, extent: CGFloat) {
        extentSlider.value = Float(extent)
        extentLabel.text = "extent: \(Int(extent))"

        for group in RegionCatalog.groups {
            content.addArrangedSubview(sectionTitle(group))
            for spec in specs where spec.group == group {
                content.addArrangedSubview(makeRow(spec,
                                                   isOn: enabled.contains(spec.id),
                                                   isAvailable: available.contains(spec.id)))
            }
        }
    }

    private func makeRow(_ spec: RegionSpec, isOn: Bool, isAvailable: Bool) -> UIView {
        let dot = UIView()
        dot.backgroundColor = spec.color
        dot.layer.cornerRadius = 6
        dot.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([dot.widthAnchor.constraint(equalToConstant: 12),
                                     dot.heightAnchor.constraint(equalToConstant: 12)])

        let code = UILabel()
        code.text = spec.code
        code.numberOfLines = 0
        code.font = .monospacedSystemFont(ofSize: 12, weight: .semibold)

        let sw = UISwitch()
        sw.isOn = isOn && isAvailable
        sw.isEnabled = isAvailable
        sw.onTintColor = spec.color
        sw.addAction(UIAction { [weak self, weak sw] _ in
            self?.onToggle?(spec.id, sw?.isOn ?? false)
        }, for: .valueChanged)
        switches[spec.id] = sw

        let top = UIStackView(arrangedSubviews: [dot, code, sw])
        top.spacing = 8
        top.alignment = .center
        code.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let note = UILabel()
        note.text = isAvailable ? spec.note : "⚠️ 이 OS 버전에서는 사용할 수 없음 (iOS 27.1+ 필요)"
        note.numberOfLines = 0
        note.font = .systemFont(ofSize: 11)
        note.textColor = .secondaryLabel

        let readout = UILabel()
        readout.numberOfLines = 0
        readout.font = .monospacedSystemFont(ofSize: 10.5, weight: .regular)
        readout.textColor = .label
        readouts[spec.id] = readout

        let v = UIStackView(arrangedSubviews: [top, note, readout])
        v.axis = .vertical
        v.spacing = 3
        v.isLayoutMarginsRelativeArrangement = true
        v.directionalLayoutMargins = .init(top: 8, leading: 10, bottom: 8, trailing: 10)
        v.backgroundColor = spec.color.withAlphaComponent(0.10)
        v.layer.cornerRadius = 12
        v.layer.cornerCurve = .continuous
        return v
    }

    // MARK: - Updates

    func setAll(_ on: Bool) {
        for (_, sw) in switches where sw.isEnabled { sw.setOn(on, animated: true) }
        onSetAll?(on)
    }

    func updateEnvironment(_ text: String) {
        if envLabel.text != text { envLabel.text = text }
    }

    func updateReadout(id: String, text: String) {
        guard let l = readouts[id], l.text != text else { return }
        l.text = text
    }

    // MARK: - Small builders

    private func sectionTitle(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.numberOfLines = 0
        l.font = .systemFont(ofSize: 13, weight: .bold)
        l.textColor = .secondaryLabel
        return l
    }

    private func row(_ a: UIView, _ b: UIView, ratio: CGFloat?) -> UIView {
        let s = UIStackView(arrangedSubviews: [a, b])
        s.spacing = 10
        s.alignment = .center
        if let ratio {
            a.widthAnchor.constraint(equalTo: s.widthAnchor, multiplier: ratio).isActive = true
        } else {
            b.setContentHuggingPriority(.required, for: .horizontal)
        }
        return s
    }
}
