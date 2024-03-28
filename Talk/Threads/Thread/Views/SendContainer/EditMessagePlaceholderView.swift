//
//  EditMessagePlaceholderView.swift
//  Talk
//
//  Created by hamed on 11/3/23.
//

import SwiftUI
import TalkViewModels
import TalkExtensions
import TalkUI
import ChatModels

struct EditMessagePlaceholderView: View {
    @EnvironmentObject var threadVM: ThreadViewModel
    @EnvironmentObject var viewModel: SendContainerViewModel

    var body: some View {
        if let editMessage = viewModel.editMessage {
            HStack {
                SendContainerButton(image: "pencil")
                EditMessageImage(editMessage: editMessage)
                VStack(alignment: .leading, spacing: 0) {
                    if let name = editMessage.participant?.name {
                        Text(name)
                            .font(.iransansBoldBody)
                            .foregroundStyle(Color.App.accent)
                    }
                    Text("\(editMessage.message ?? "")")
                        .font(.iransansCaption2)
                        .foregroundColor(Color.App.textPlaceholder)
                        .onTapGesture {
                            // TODO: Go to reply message location
                        }
                }

                Spacer()
                CloseButton {
                    threadVM.scrollVM.disableExcessiveLoading()
                    viewModel.clear()
                }
                .padding(.trailing, 4)
            }
            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .bottom)))
            .onAppear {
                if let messageId = editMessage.id, let uniqueId = editMessage.uniqueId, messageId == threadVM.thread.lastMessageVO?.id {
                    threadVM.scrollVM.showHighlighted(uniqueId, messageId, highlight: false)
                }
            }
        }
    }
}

struct EditMessageImage: View {
    let editMessage: Message
    @EnvironmentObject var viewModel: ThreadHistoryViewModel

    var body: some View {
        if let viewModel = viewModel.messageViewModel(for: editMessage) {
            if viewModel.message.isImage {
                image(viewModel: viewModel)
            } else if viewModel.message.isFileType {
                iconImage(viewModel: viewModel)
            }
        }
    }

    @ViewBuilder func image(viewModel: MessageRowViewModel) -> some View {
        if viewModel.message.isImage {
                Image(uiImage: viewModel.image)
                .interpolation(.none)
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .clipped()
        }
    }


    @ViewBuilder func iconImage(viewModel: MessageRowViewModel) -> some View {
        if viewModel.message.isFileType, let iconName = viewModel.message.iconName {
            Image(systemName: iconName)
                .interpolation(.none)
                .resizable()
                .scaledToFill()
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .foregroundColor(Color.App.accent)
                .clipped()
        }
    }
}

struct EditMessagePlaceholderView_Previews: PreviewProvider {
    struct Preview: View {
        var viewModel: ThreadViewModel {
            let viewModel = ThreadViewModel(thread: .init(id: 1))
            viewModel.sendContainerViewModel.editMessage = .init(threadId: 1,
                                          message: "Test message", messageType: .text,
                                          participant: .init(name: "John Doe"))
            return viewModel
        }

        var body: some View {
            EditMessagePlaceholderView()
                .environmentObject(viewModel)
        }
    }

    static var previews: some View {
        Preview()
    }
}
