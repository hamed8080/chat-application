//
//  ForwardMessageRow.swift
//  Talk
//
//  Created by hamed on 6/27/23.
//

import AdditiveUI
import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels

struct ForwardMessageRow: View {
    @EnvironmentObject var viewModel: MessageRowViewModel
    var message: Message? { viewModel.message }
    @EnvironmentObject var navVM: NavigationModel
    @State private var contentSize: CGSize = .zero

    var body: some View {
        if let forwardInfo = message?.forwardInfo, let forwardThread = forwardInfo.conversation {
            Button {
                navVM.append(thread: forwardThread)
            } label: {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(viewModel.isMe ? Color.App.primary : Color.App.pink)
                        .frame(width: 3)
                        .frame(height: contentSize.height)
                    VStack(alignment: .leading, spacing: 4) {
                        if let name = forwardInfo.participant?.name {
                            Text(name)
                                .font(.iransansCaption2)
                                .foregroundStyle(viewModel.isMe ? Color.App.primary : Color.App.text)
                        }
                        if !(message?.messageTitle.isEmpty ?? true) {
                            Text(viewModel.markdownTitle)
                                .font(.iransansCaption2)
                                .foregroundStyle(Color.App.gray2)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .background(
                        GeometryReader { reader -> Color in
                            DispatchQueue.main.async {
                                contentSize = reader.size
                            }
                            return Color.clear
                        }
                    )
                }
            }
            .environment(\.layoutDirection, viewModel.isMe ? .rightToLeft : .leftToRight)
            .buttonStyle(.borderless)
            .frame(minHeight: 36)
            .truncationMode(.tail)
            .contentShape(Rectangle())
        }
    }
}
