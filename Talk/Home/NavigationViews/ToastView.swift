//
//  ToastView.swift
//  Talk
//
//  Created by hamed on 10/7/23.
//

import SwiftUI
import TalkViewModels
import TalkUI

public struct ToastView<ContentView: View>: View {
    @EnvironmentObject var appState: AppState
    let title: String?
    let message: String
    let titleFont: Font
    let messageFont: Font
    let leadingView: () -> ContentView

    public init(title: String? = nil,
                message: String,
                titleFont: Font = .iransansBoldBody,
                messageFont: Font = .iransansCaption,
                @ViewBuilder leadingView: @escaping () -> ContentView)
    {
        self.title = title
        self.message = message
        self.leadingView = leadingView
        self.titleFont = titleFont
        self.messageFont = messageFont
    }

    public var body: some View {
        GeometryReader { reader in
            VStack {
                VStack(alignment: .leading, spacing: 0) {
                    if let title = title {
                        Text(title)
                            .font(titleFont)
                    }
                    HStack(spacing: 0) {
                        leadingView()
                        Text(message)
                            .font(messageFont)
                            .foregroundStyle(Color.App.red)
                        Spacer()
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.top, 96)
        }
    }
}

struct ToastView_Previews: PreviewProvider {
    static var previews: some View {
        ToastView(message: "TEST") {}
    }
}
