//
//  CircleProgressButton.swift
//
//
//  Created by hamed on 1/3/24.
//

import Foundation
import UIKit
import SwiftUI

public final class CircleProgressButton: UIButton {
    private var progressColor: UIColor?
    private var bgColor: UIColor?
    private var shapeLayer = CAShapeLayer()
    private let imgCenter = UIImageView()
    private var iconTint: UIColor?
    private var animation = CABasicAnimation(keyPath: "strokeEnd")

    public init(progressColor: UIColor? = .darkText, iconTint: UIColor? = Color.App.textPrimaryUIColor, bgColor: UIColor? = .white.withAlphaComponent(0.3)) {
        super.init(frame: .zero)
        self.bgColor = bgColor
        self.progressColor = progressColor
        self.iconTint = iconTint
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        imgCenter.translatesAutoresizingMaskIntoConstraints = false
        imgCenter.contentMode = .scaleAspectFit
        imgCenter.tintColor = iconTint
        addSubview(imgCenter)
        layer.backgroundColor = bgColor?.cgColor
        NSLayoutConstraint.activate([
            imgCenter.centerXAnchor.constraint(equalTo: centerXAnchor),
            imgCenter.centerYAnchor.constraint(equalTo: centerYAnchor),
            imgCenter.widthAnchor.constraint(equalToConstant: 16),
            imgCenter.heightAnchor.constraint(equalToConstant: 16),
        ])
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2
        drawProgress()
    }

    private func drawProgress() {
        let margin: CGFloat = 6
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let path = UIBezierPath(arcCenter: center,
                                radius: (bounds.width / 2) - margin,
                                startAngle: -CGFloat.pi / 2,
                                endAngle: 2 * CGFloat.pi,
                                clockwise: true)

        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = progressColor?.cgColor
        shapeLayer.path = path.cgPath
        shapeLayer.lineCap = .round
        shapeLayer.lineWidth = 3
        layer.addSublayer(shapeLayer)
    }

    public func animate(to progress: CGFloat, systemIconName: String = "") {
        let font = UIFont.systemFont(ofSize: 8, weight: .bold)
        let config = UIImage.SymbolConfiguration(font: font)
        imgCenter.image = UIImage(systemName: systemIconName, withConfiguration: config)
        animation.toValue = progress
        animation.duration = 0.3
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.isRemovedOnCompletion = false
        shapeLayer.strokeEnd = progress
        shapeLayer.add(animation, forKey: "strokeEndAnimation")
    }

    public func setProgressVisibility(visible: Bool) {
        shapeLayer.isHidden = !visible
    }
}
