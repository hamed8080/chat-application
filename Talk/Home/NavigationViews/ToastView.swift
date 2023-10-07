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
                titleFont: Font = .iransansBoldSubtitle,
                messageFont: Font = .iransansBody,
                @ViewBuilder leadingView: @escaping () -> ContentView)
    {
        self.title = title
        self.message = message
        self.leadingView = leadingView
        self.titleFont = titleFont
        self.messageFont = messageFont
    }

    public var body: some View {
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
                    Spacer()
                }
            }
            .padding(.top, 72)
            .padding([.leading, .trailing, .bottom])
            .background(.ultraThinMaterial)
            Spacer()
        }
    }
}

struct ToastView_Previews: PreviewProvider {
    static var previews: some View {
        ToastView(message: "TEST") {}
    }
}
