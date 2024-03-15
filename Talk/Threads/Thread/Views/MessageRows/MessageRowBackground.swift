//
//  MessageRowBackground.swift
//  Talk
//
//  Created by hamed on 11/20/23.
//

import SwiftUI

class MessageRowBackground: CAShapeLayer {
    static let tailSize: CGSize = .init(width: 6, height: 12)

    override init() {
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func drawPath(color: CGColor, rect: CGRect) {
        let tailWidth = MessageRowBackground.tailSize.width
        let tailHeight = MessageRowBackground.tailSize.height
        let mainCornerRadius: CGFloat = 12
        let roundedCorner: CGFloat = 1
        let roundeedRect = CGRect(x: 0, y: 0, width: rect.width - tailWidth, height: rect.height)

        let path = UIBezierPath(roundedRect: roundeedRect, cornerRadius: mainCornerRadius)
//        path.move(to: .init(x: tailWidth, y: rect.height - tailHeight))
//        path.addQuadCurve(
//            to: .init(x: roundedCorner * 2, y: rect.height - roundedCorner),
//            controlPoint: .init(x: tailWidth, y: rect.height - roundedCorner)
//        )
//        path.addArc(
//            withCenter: .init(x: (roundedCorner / 2), y: rect.height - (roundedCorner / 2)),
//            radius: roundedCorner / 2,
//            startAngle: CGFloat(90).degree,
//            endAngle: CGFloat(270).degree,
//            clockwise: false
//        )
//        path.addLine(to: .init(x: tailWidth + mainCornerRadius, y: rect.height))

        //design path in layer
        self.path = path.cgPath
        fillColor = color
        frame = rect
    }
}


struct MessageRowBackgroundSwiftUI: Shape {
    let showTail: Bool
    static let withTail = MessageRowBackgroundSwiftUI(showTail: true)
    static let noTail = MessageRowBackgroundSwiftUI(showTail: false)
    static let tailSize: CGSize = .init(width: 6, height: 12)

    func path(in rect: CGRect) -> Path {
        Path { path in
            let roundedCorner: CGFloat = 3
            let roundeedRect = CGRect(x: 0, y: 0, width: rect.width - MessageRowBackground.tailSize.width, height: rect.height)
            path.addRoundedRect(in: roundeedRect, cornerSize: .init(width: 12, height: 12))
            if showTail {
                path.move(to: .init(x: roundeedRect.width, y: rect.height - MessageRowBackground.tailSize.height))
                path.addQuadCurve(
                    to: .init(x: rect.width - (roundedCorner / 2), y: rect.height - roundedCorner),
                    control: .init(x: roundeedRect.width, y: rect.height - (MessageRowBackground.tailSize.height / 2))
                )
                path.addArc(
                    center: .init(x: rect.width - roundedCorner / 2, y: rect.height - roundedCorner / 2), radius: roundedCorner / 2,
                    startAngle: .degrees(0), endAngle: .degrees(450),
                    clockwise: false
                )
                path.addLine(to: .init(x: roundeedRect.width - (MessageRowBackground.tailSize.width * 2), y: rect.height))
            }
        }
    }
}
