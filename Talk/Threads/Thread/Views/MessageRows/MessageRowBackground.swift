//
//  MessageRowBackground.swift
//  Talk
//
//  Created by hamed on 11/20/23.
//

import SwiftUI
import TalkViewModels

struct MessageRowBackground: Shape {
    let showTail: Bool
    static let withTail = MessageRowBackground(showTail: true)
    static let noTail = MessageRowBackground(showTail: false)

    func path(in rect: CGRect) -> Path {
        Path { path in
            let roundedCorner: CGFloat = 3
            let roundeedRect = CGRect(x: 0, y: 0, width: rect.width - MessageRowSizes.tailSize.width, height: rect.height)
            path.addRoundedRect(in: roundeedRect, cornerSize: .init(width: 12, height: 12))
            if showTail {
                path.move(to: .init(x: roundeedRect.width, y: rect.height - MessageRowSizes.tailSize.height))
                path.addQuadCurve(
                    to: .init(x: rect.width - (roundedCorner / 2), y: rect.height - roundedCorner),
                    control: .init(x: roundeedRect.width, y: rect.height - (MessageRowSizes.tailSize.height / 2))
                )
                path.addArc(
                    center: .init(x: rect.width - roundedCorner / 2, y: rect.height - roundedCorner / 2), radius: roundedCorner / 2,
                    startAngle: .degrees(0), endAngle: .degrees(450),
                    clockwise: false
                )
                path.addLine(to: .init(x: roundeedRect.width - (MessageRowSizes.tailSize.width * 2), y: rect.height))
            }
        }
    }
}
