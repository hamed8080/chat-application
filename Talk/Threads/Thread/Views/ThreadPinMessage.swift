//
//  ThreadPinMessage.swift
//  Talk
//
//  Created by hamed on 3/13/23.
//

import Chat
import ChatDTO
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels

struct ThreadPinMessage: View {
    @EnvironmentObject var viewModel: ThreadPinMessageViewModel
    let threadVM: ThreadViewModel

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.hasPinMessage {
                HStack {
                    if viewModel.isEnglish {
                        LTRDesign
                    } else {
                        RTLDesign
                    }
                }
                .padding(EdgeInsets(top: 0, leading: viewModel.isEnglish ? 4 : 8, bottom: 0, trailing: viewModel.isEnglish ? 8 : 4))
                .frame(height: 40)
                .background(MixMaterialBackground())
                .transition(.asymmetric(insertion: .push(from: .top), removal: .move(edge: .top)))
                .onTapGesture {
                    if let time = viewModel.message?.time, let messageId = viewModel.message?.messageId {
                        threadVM.historyVM.moveToTime(time, messageId)
                    }
                }
            }
        }
    }

    @ViewBuilder private var LTRDesign: some View {
        closeButton
        Spacer()
        imageView
        textView
        pinIcon
        separator
    }

    @ViewBuilder private var RTLDesign: some View {
        separator
        pinIcon
        imageView
        textView
        Spacer()
        closeButton
    }

    private var separator: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.App.accent)
            .frame(width: 3, height: 24)
    }

    private var pinIcon: some View {
        Image(systemName: "pin.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 10, height: 12)
            .foregroundColor(Color.App.accent)
    }

    private var textView: some View {
        Text(viewModel.title)
            .font(.iransansBody)
    }

    @ViewBuilder private var imageView: some View {
        if let image = viewModel.image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 24, height: 24)
                .clipShape(RoundedRectangle(cornerRadius:(4)))
        } else if let icon = viewModel.icon {
            Image(systemName: icon)
                .resizable()
                .scaledToFill()
                .frame(width: 24, height: 24)
                .foregroundStyle(Color.App.textSecondary, .clear)
        }
    }

    var closeButton: some View {
        Button {
            withAnimation {
                viewModel.unpinMessage(viewModel.message?.messageId ?? -1)
            }
        } label: {
            Image(systemName: "xmark")
                .resizable()
                .scaledToFit()
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color.App.iconSecondary)
                .frame(width: 12, height: 12)
        }
        .frame(width: 36, height: 36)
        .buttonStyle(.borderless)
        .fontWeight(.light)
    }
}

struct ThreadPinMessage_Previews: PreviewProvider {
    static var previews: some View {
        ThreadPinMessage(threadVM: ThreadViewModel(thread: Conversation()))
    }
}
