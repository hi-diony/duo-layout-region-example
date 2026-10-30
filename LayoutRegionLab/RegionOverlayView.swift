import UIKit

/// view.layoutGuide(for: region) 에 네 변을 붙여서 그 영역을 색으로 보여주는 뷰.
final class RegionOverlayView: UIView {
    let spec: RegionSpec
    var regionConstraints: [NSLayoutConstraint] = []
    private(set) var guide: UILayoutGuide?
    private let badge = UILabel()

    init(spec: RegionSpec, slot: Int) {
        self.spec = spec
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = false
        backgroundColor = spec.color.withAlphaComponent(0.18)
        layer.borderColor = spec.color.cgColor
        layer.borderWidth = 3

        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.text = " \(spec.code) "
        badge.font = .monospacedSystemFont(ofSize: 10, weight: .semibold)
        badge.textColor = spec.color.readableTextColor
        badge.backgroundColor = spec.color
        badge.layer.cornerRadius = 4
        badge.clipsToBounds = true
        addSubview(badge)

        // 같은 모서리에 배지가 겹치지 않도록 슬롯별로 모서리/줄을 분산
        let corner = slot % 4
        let offset = CGFloat(slot / 4) * 16 + 3
        var c: [NSLayoutConstraint] = []
        switch corner {
        case 0:
            c = [badge.topAnchor.constraint(equalTo: topAnchor, constant: offset),
                 badge.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 3)]
        case 1:
            c = [badge.topAnchor.constraint(equalTo: topAnchor, constant: offset),
                 badge.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -3)]
        case 2:
            c = [badge.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -offset),
                 badge.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 3)]
        default:
            c = [badge.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -offset),
                 badge.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -3)]
        }
        NSLayoutConstraint.activate(c)
    }

    required init?(coder: NSCoder) { fatalError() }

    /// host 뷰의 layoutGuide(for:) 에 붙인다. 쓸 수 없는 OS면 false.
    @discardableResult
    func attach(to host: UIView, extent: CGFloat) -> Bool {
        NSLayoutConstraint.deactivate(regionConstraints)
        regionConstraints = []
        guard let region = spec.make(extent) else {
            guide = nil
            return false
        }
        let g = host.layoutGuide(for: region)
        guide = g
        regionConstraints = [
            topAnchor.constraint(equalTo: g.topAnchor),
            bottomAnchor.constraint(equalTo: g.bottomAnchor),
            leadingAnchor.constraint(equalTo: g.leadingAnchor),
            trailingAnchor.constraint(equalTo: g.trailingAnchor),
        ]
        NSLayoutConstraint.activate(regionConstraints)
        return true
    }
}
