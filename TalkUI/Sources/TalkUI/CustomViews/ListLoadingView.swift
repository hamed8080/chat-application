//
//  ListLoadingView.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 6/7/21.
//

import AdditiveUI
import SwiftUI

public struct ListLoadingView: View {
    @Binding var isLoading: Bool
    @State var isAnimating: Bool = false

    public init(isLoading: Binding<Bool>) {
        self._isLoading = isLoading
    }

    public var body: some View {
        HStack {
            Spacer()
            Circle()
                .trim(from: 0, to: isAnimating ? 1 : 0.1)
                .stroke(style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round, miterLimit: 10))
                .fill(AngularGradient(colors: [.red, .random, .random, .teal], center: .top))
                .frame(width: isLoading ? 24 : 0, height: isLoading ? 24 : 0)
                .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                .onAppear {
                    DispatchQueue.main.async {
                        withAnimation(.easeInOut(duration: 2).delay(0.05).repeatForever(autoreverses: true)) {
                            self.isAnimating.toggle()
                        }
                    }
                }
                .noSeparators()
            Spacer()
        }
        .scaleEffect(x: isLoading ? 1 : 0.0001, y: isLoading ? 1 : 0.0001, anchor: .center)
    }
}
