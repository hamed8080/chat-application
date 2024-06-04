//
//  ThreadPinMessage.swift
//  Talk
//
//  Created by hamed on 3/13/23.
//

import Chat
import SwiftUI
import TalkUI
import TalkViewModels

struct ThreadPinMessage: View {
    @EnvironmentObject var viewModel: ThreadPinMessageViewModel
    let threadVM: ThreadViewModel
    @State private var isPressing = false

    var body: some View {
        HStack {
            if viewModel.hasPinMessage {
                if viewModel.isEnglish {
                    LTRDesign
                } else {
                    RTLDesign
                }
            }
        }
        .contentShape(Rectangle())
        .padding(EdgeInsets(top: 0, leading: leadingPadding, bottom: 0, trailing: trailingPadding))
        .frame(height: viewModel.hasPinMessage ? 40 : 0)
        .background(MixMaterialBackground())
        .transition(.asymmetric(insertion: .push(from: .top), removal: .move(edge: .top)))
        .clipped()
        .onTapGesture {
            Task {
                if let time = viewModel.message?.time, let messageId = viewModel.message?.messageId {
                    await threadVM.historyVM.moveToTime(time, messageId)
                }
            }
        }
    }

    private var leadingPadding: CGFloat {
        if !viewModel.hasPinMessage { return 0 }
        return viewModel.isEnglish ? 4 : 8
    }

    private var trailingPadding: CGFloat {
        if !viewModel.hasPinMessage { return 0 }
        return viewModel.isEnglish ? 8 : 4
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
            .disabled(true)
    }

    private var pinIcon: some View {
        Image(systemName: "pin.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 10, height: 12)
            .foregroundColor(Color.App.accent)
            .disabled(true)
    }

    private var textView: some View {
        Text(viewModel.title)
            .font(.iransansBody)
            .disabled(true)
    }

    @ViewBuilder private var imageView: some View {
        if let image = viewModel.image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 24, height: 24)
                .clipShape(RoundedRectangle(cornerRadius:(4)))
                .disabled(true)
        } else if let icon = viewModel.icon {
            Image(systemName: icon)
                .resizable()
                .scaledToFill()
                .frame(width: 24, height: 24)
                .foregroundStyle(Color.App.textSecondary, .clear)
                .disabled(true)
        }
    }

    @ViewBuilder var closeButton: some View {
        if viewModel.hasPinMessage {
            Image(systemName: "xmark")
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.App.textSecondary)
                .fontWeight(.bold)
                .padding(viewModel.hasPinMessage ? 12 : 0)
                .frame(width: threadVM.thread.admin == true ? 36 : 0, height: threadVM.thread.admin == true ? 36 : 0)
                .clipShape(Rectangle())
                .opacity(isPressing ? 0.5 : 1.0)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation {
                        viewModel.unpinMessage(viewModel.message?.messageId ?? -1)
                    }
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .global)
                        .onChanged { newValue in
                            isPressing = true
                        }
                        .onEnded { newValue in
                            isPressing = false
                        }
                )
                .animation(.easeInOut, value: isPressing)
        }
    }
}

struct ThreadPinMessage_Previews: PreviewProvider {
    static var previews: some View {
        ThreadPinMessage(threadVM: ThreadViewModel(thread: Conversation()))
    }
}
