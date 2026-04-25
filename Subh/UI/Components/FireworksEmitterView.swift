import SwiftUI
import UIKit

struct FireworksEmitterView: UIViewRepresentable {
    let trigger: Int

    func makeUIView(context: Context) -> FireworksEmitterHostView {
        FireworksEmitterHostView()
    }

    func updateUIView(_ uiView: FireworksEmitterHostView, context: Context) {
        uiView.runBurst(trigger: trigger)
    }
}

final class FireworksEmitterHostView: UIView {
    private let emitterLayer = CAEmitterLayer()
    private var lastTrigger: Int = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        clipsToBounds = true
        layer.addSublayer(emitterLayer)
        configureEmitter()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
        emitterLayer.emitterSize = CGSize(width: bounds.width, height: bounds.height * 0.4)
        emitterLayer.frame = bounds
    }

    func runBurst(trigger: Int) {
        guard trigger > lastTrigger else { return }
        lastTrigger = trigger
        emitterLayer.birthRate = 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            self?.emitterLayer.birthRate = 0
        }
    }

    private func configureEmitter() {
        emitterLayer.emitterShape = .rectangle
        emitterLayer.emitterMode = .outline
        emitterLayer.renderMode = .additive
        emitterLayer.birthRate = 0
        emitterLayer.emitterCells = [makeCell(color: UIColor(DawnColor.highlight)), makeCell(color: UIColor(DawnColor.accent))]
    }

    private func makeCell(color: UIColor) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.birthRate = 28
        cell.lifetime = 1.6
        cell.velocity = 180
        cell.velocityRange = 60
        cell.yAcceleration = 140
        cell.emissionRange = .pi * 2
        cell.scale = 0.04
        cell.scaleRange = 0.02
        cell.spin = 2.4
        cell.spinRange = 3.2
        cell.color = color.cgColor
        cell.contents = UIImage(systemName: "sparkle")?.withTintColor(color, renderingMode: .alwaysOriginal).cgImage
        return cell
    }
}
