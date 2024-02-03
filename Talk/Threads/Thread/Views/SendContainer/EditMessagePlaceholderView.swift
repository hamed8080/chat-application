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

struct EditMessagePlaceholderView: View {
    @EnvironmentObject var viewModel: ThreadViewModel

    var body: some View {
        if let editMessage = viewModel.sendContainerViewModel.editMessage {
            HStack {
                SendContainerButton(image: "pencil")
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
                    viewModel.scrollVM.disableExcessiveLoading()
                    viewModel.sendContainerViewModel.isInEditMode = false
                    viewModel.sendContainerViewModel.editMessage = nil
                    viewModel.sendContainerViewModel.textMessage = ""
                    viewModel.animateObjectWillChange()
                }
                .padding(.trailing, 4)
            }
            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .bottom)))
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
