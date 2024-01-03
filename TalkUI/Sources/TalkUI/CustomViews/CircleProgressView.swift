//
//  CircleProgressView.swift
//  
//
//  Created by hamed on 1/3/24.
//

import Foundation
import UIKit

public final class CircleProgressView: UIView {
    public var color: UIColor?
    private var progress: CGFloat = 0

    public convenience init() {
        self.init(frame: .init(x: 0, y: 0, width: 0, height: 0))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        let margin: CGFloat = 4
        let rect = CGRect(x: 0, y: 0, width: frame.size.width - margin, height: frame.size.height - margin)
        let path = UIBezierPath(arcCenter: .init(x: (rect.width / 2.0) + margin / 2, y: (rect.height / 2.0) + margin / 2),
                                radius: rect.width / 2,
                                startAngle: CGFloat(0).degree,
                                endAngle: CGFloat(90).degree,
                                clockwise: false)

        let shapeLayer = CAShapeLayer()
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = color?.cgColor
        shapeLayer.path = path.cgPath
        shapeLayer.lineCap = .round
        shapeLayer.borderWidth = 2

        layer.addSublayer(shapeLayer)
    }

    override public func draw(_ rect: CGRect) {
        super.draw(rect)
        configureView()
    }

    public func setProgress(_ progress: CGFloat) {
        self.progress = progress
    }
}

