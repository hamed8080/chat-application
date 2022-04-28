//
//  LoadingView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI

struct LoadingView: View {
    var isAnimating          : Binding<Bool>
    let count                : UInt
    let width                : CGFloat
    let spacing              : CGFloat
    let color                : Color
    
    init(isAnimating:Binding<Bool>, count:UInt = 4, width:CGFloat = 3, spacing:CGFloat = 1, color:Color = .orange) {
        self.isAnimating = isAnimating
        self.count      = count
        self.width      = width
        self.spacing    = spacing
        self.color      = color
    }

    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<Int(count)) { index in
                item(forIndex: index, in: geometry.size)
                    .rotationEffect(isAnimating.wrappedValue ? .degrees(360) : .degrees(0))
                    .animation(
                        Animation.default
                            .speed(Double.random(in: 0.2...0.5))
                            .repeatCount(isAnimating.wrappedValue ? .max : 1, autoreverses: false),
                        value: isAnimating.wrappedValue
                    )
            }
        }
        .foregroundColor(color)
        .aspectRatio(contentMode: .fit)
    }

    private func item(forIndex index: Int, in geometrySize: CGSize) -> some View {
        Group { () -> Path in
            var p = Path()
            p.addArc(center: CGPoint(x: geometrySize.width/2, y: geometrySize.height/2),
                     radius: geometrySize.width/2 - width/2 - CGFloat(index) * (width + spacing),
                     startAngle: .degrees(0),
                     endAngle: .degrees(Double(Int.random(in: 120...300))),
                     clockwise: true)
            return p.strokedPath(.init(lineWidth: width))
        }
        .frame(width: geometrySize.width, height: geometrySize.height)
    }
}


struct LoadingView_Previews: PreviewProvider {
    
    @State static var isAnimating = true
    
    static var previews: some View {
        LoadingView(isAnimating: $isAnimating, count: 4, width: 48, spacing: 12)
    }
}
