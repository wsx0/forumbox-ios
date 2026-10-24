import UIKit

/// 渐变背景视图（非夜樱主题使用）
final class GradientView: UIView {

    override class var layerClass: AnyClass { return CAGradientLayer.self }

    var gradientLayer: CAGradientLayer { return layer as! CAGradientLayer }

    init(frame: CGRect, top: UIColor, bottom: UIColor) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        gradientLayer.colors = [top.cgColor, bottom.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.2, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.8, y: 1)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// 樱花飘落粒子层（夜樱主题使用）
final class SakuraPetalView: UIView {

    override class var layerClass: AnyClass { return CAEmitterLayer.self }

    private var emitter: CAEmitterLayer { return layer as! CAEmitterLayer }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func start() {
        guard let image = UIImage(named: "Petal")?.cgImage else { return }
        let cell = CAEmitterCell()
        cell.contents = image
        cell.birthRate = 0.45
        cell.lifetime = 24
        cell.velocity = 38
        cell.velocityRange = 22
        cell.emissionLongitude = .pi / 2
        cell.emissionRange = .pi / 5
        cell.yAcceleration = 8
        cell.spin = 1.1
        cell.spinRange = 2.2
        cell.scale = 0.42
        cell.scaleRange = 0.24
        cell.alphaSpeed = -0.015
        emitter.emitterCells = [cell]
        emitter.emitterShape = .line
        emitter.emitterMode = .outline
        emitter.renderMode = .unordered
        emitter.seed = 7
        updateEmitterLayout()
    }

    func stop() {
        emitter.birthRate = 0
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateEmitterLayout()
    }

    private func updateEmitterLayout() {
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: -24)
        emitter.emitterSize = CGSize(width: max(bounds.width, 1), height: 1)
    }
}
