//
//  MessageRowBackground.swift
//  Talk
//
//  Created by hamed on 11/20/23.
//

import SwiftUI

//struct MessageRowBackground: Shape {
//    static let instance = MessageRowBackground()
//    static let tailSize: CGSize = .init(width: 6, height: 12)
//
//    func path(in rect: CGRect) -> Path {
//        Path { path in
//            let roundedCorner: CGFloat = 3
//            let roundeedRect = CGRect(x: 0, y: 0, width: rect.width - MessageRowBackground.tailSize.width, height: rect.height)
//            path.addRoundedRect(in: roundeedRect, cornerSize: .init(width: 12, height: 12))
//            path.move(to: .init(x: roundeedRect.width, y: rect.height - MessageRowBackground.tailSize.height))
//            path.addQuadCurve(
//                to: .init(x: rect.width - (roundedCorner / 2), y: rect.height - roundedCorner),
//                control: .init(x: roundeedRect.width, y: rect.height - (MessageRowBackground.tailSize.height / 2))
//            )
//            path.addArc(
//                center: .init(x: rect.width - roundedCorner / 2, y: rect.height - roundedCorner / 2), radius: roundedCorner / 2,
//                startAngle: .degrees(0), endAngle: .degrees(450),
//                clockwise: false
//            )
//            path.addLine(to: .init(x: roundeedRect.width - (MessageRowBackground.tailSize.width * 2), y: rect.height))
//        }
//    }
//}

class MessageRowBackground: CALayer {
    static let tailSize: CGSize = .init(width: 6, height: 12)
    private var path = UIBezierPath()

    init(color: UIColor) {
        super.init()
        drawPath(color: color)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func drawPath(color: UIColor) {
        let rect = frame
        let roundedCorner: CGFloat = 3
        let roundeedRect = CGRect(x: 0, y: 0, width: rect.width - MessageRowBackground.tailSize.width, height: rect.height)
        path = UIBezierPath(roundedRect: roundeedRect, cornerRadius: 12)
        path.move(to: .init(x: roundeedRect.width, y: rect.height - MessageRowBackground.tailSize.height))
        path.addQuadCurve(
            to: .init(x: rect.width - (roundedCorner / 2), y: rect.height - roundedCorner),
            controlPoint: .init(x: roundeedRect.width, y: rect.height - (MessageRowBackground.tailSize.height / 2))
        )
        path.addArc(
            withCenter: .init(x: rect.width - roundedCorner / 2, y: rect.height - roundedCorner / 2), radius: roundedCorner / 2,
            startAngle: CGFloat(0).degree, endAngle: CGFloat(450).degree,
            clockwise: false
        )
        path.addLine(to: .init(x: roundeedRect.width - (MessageRowBackground.tailSize.width * 2), y: rect.height))

        //design path in layer
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = color.cgColor

        addSublayer(shapeLayer)
    }
}
