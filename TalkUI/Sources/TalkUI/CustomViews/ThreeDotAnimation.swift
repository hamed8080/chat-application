//
//  ThreeDotAnimation.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 6/7/21.
//

import SwiftUI

struct ThreeDotAnimation: View {
    @State private var dot1Opacity: Double = 0
    @State private var dot2Opacity: Double = 0
    @State private var dot3Opacity: Double = 0

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .opacity(dot1Opacity)
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 0.8).repeatForever()) {
                        dot1Opacity = 1
                    }
                }

            Circle()
                .opacity(dot2Opacity)
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 0.8).repeatForever().delay(0.3)) {
                        dot2Opacity = 1
                    }
                }

            Circle()
                .opacity(dot3Opacity)
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 0.8).repeatForever().delay(0.6)) {
                        dot3Opacity = 1
                    }
                }
        }
        .font(.iransansBoldCaption3)
        .foregroundColor(.hint)
    }
}
struct ThreeDotAnimation_Previews: PreviewProvider {
    static var previews: some View {
        ThreeDotAnimation()
    }
}
