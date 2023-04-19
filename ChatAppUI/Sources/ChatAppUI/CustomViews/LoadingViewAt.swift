//
//  LoadingViewAt.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/7/21.
//

import AdditiveUI
import SwiftUI

public enum LoadingViewPosition {
    case TOP
    case CENTER
    case BOTTOM
}

public struct LoadingViewAt: View {
    var at: LoadingViewPosition = .BOTTOM
    var isLoading: Bool
    var reader: GeometryProxy
    var size: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 36 : 28
    }

    public var body: some View {
        if isLoading {
            LoadingView(width: 3)
                .frame(width: size, height: size, alignment: .center)
                .offset(x: reader.size.width / 2 - (size / 2), y: reader.size.height - position(reader: reader))
        }
    }

    func position(reader: GeometryProxy) -> CGFloat {
        switch at {
        case .TOP:
            return reader.size.height
        case .CENTER:
            return reader.size.height / 2
        case .BOTTOM:
            return reader.safeAreaInsets.bottom > 0 ? max(size, reader.safeAreaInsets.bottom) : size
        }
    }
}

public struct ListLoadingView: View {
    @Binding var isLoading: Bool

    public init(isLoading: Binding<Bool>) {
        self._isLoading = isLoading
    }

    public var body: some View {
        if isLoading {
            HStack {
                Spacer()
                LoadingView(isAnimating: true, width: 3)
                    .frame(width: 24, height: 24)
                    .noSeparators()
                Spacer()
            }
        }
    }
}
