//
//  ShimmerViewModifier.swift
//  Talk
//
//  Created by hamed on 2/6/24.
//

import SwiftUI
import TalkViewModels

public struct ShimmerViewModifier: ViewModifier {
    @EnvironmentObject var viewModel: ShimmerItemViewModel
    let cornerRadius: CGFloat

    public init(cornerRadius: CGFloat) {
        self.cornerRadius = cornerRadius
    }

    private static let colors: [Color] = [
        Color("shimmer_item").opacity(0.6),
        Color("shimmer_item").opacity(0.4),
        Color("shimmer_item").opacity(0.3),
    ]

    public func body(content: Content) -> some View {
        content
            .overlay {
                LinearGradient(
                    colors: viewModel.isAnimating ? ShimmerViewModifier.colors : [Color("shimmer_item").opacity(0.6)],
                    startPoint: .leading,
                    endPoint: viewModel.isAnimating ? .trailing : .leading
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))            
    }
}

public extension View {
    func shimmer(cornerRadius: CGFloat = 4) -> some View {
        modifier(ShimmerViewModifier(cornerRadius: cornerRadius))
    }
}
