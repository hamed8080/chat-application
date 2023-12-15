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
    let title: String?
    let message: String
    let titleFont: Font
    let messageFont: Font
    let messageColor: Color
    let leadingView: () -> ContentView

    public init(title: String? = nil,
                message: String,
                messageColor: Color = Color.App.red,
                titleFont: Font = .iransansBoldBody,
                messageFont: Font = .iransansCaption,
                @ViewBuilder leadingView: @escaping () -> ContentView)
    {
        self.title = title
        self.message = message
        self.leadingView = leadingView
        self.titleFont = titleFont
        self.messageFont = messageFont
        self.messageColor = messageColor
    }

    public var body: some View {
        GeometryReader { reader in
            VStack {
                Spacer()
                VStack(alignment: .leading, spacing: 0) {
                    if let title = title {
                        Text(title)
                            .font(titleFont)
                    }
                    HStack(spacing: 8) {
                        leadingView()
                        Text(String(localized: .init(message)))
                            .font(messageFont)
                            .fontWeight(.semibold)
                            .foregroundStyle(messageColor)
                        Spacer()
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius:(12)))
                .frame(maxWidth: 380)
            }
            .padding(EdgeInsets(top: 0, leading: 8, bottom: 96, trailing: 8))
        }
    }
}

struct ToastView_Previews: PreviewProvider {
    static var previews: some View {
        ToastView(message: "TEST") {}
    }
}
