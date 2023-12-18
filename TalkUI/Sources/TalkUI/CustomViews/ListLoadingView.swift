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
    public var color: Color = .orange
    @State private var timer: Timer?

    public init(isLoading: Binding<Bool>, color: Color = Color.App.primary) {
        self._isLoading = isLoading
        self.color = color
    }

    public var body: some View {
        if isLoading {
            HStack {
                Spacer()
                Circle()
                    .trim(from: 0, to: $isAnimating.wrappedValue ? 1 : 0.1)
                    .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, miterLimit: 10))
                    .fill(AngularGradient(colors: [color, .random, .random, .teal], center: .top))
                    .frame(width: 24, height: 24)
                    .rotationEffect(Angle(degrees: $isAnimating.wrappedValue ? 360 : 0))
                    .onAppear {
                        DispatchQueue.main.async {
                            withAnimation(.easeInOut(duration: 2).delay(0.05)) {
                                self.isAnimating.toggle()
                            }
                        }
                    }
                    .task {
                        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { timer in
                            if timer.isValid, isLoading {
                                DispatchQueue.main.async {
                                    withAnimation(.easeInOut(duration: 2).delay(0.05)) {
                                        self.isAnimating.toggle()
                                    }
                                }
                            } else {
                                self.timer?.invalidate()
                                self.timer = nil
                            }
                        }
                    }
                Spacer()
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
        }
    }
}
