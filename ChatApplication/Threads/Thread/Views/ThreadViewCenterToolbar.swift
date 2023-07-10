//
//  ThreadViewCenterToolbar.swift
//  ChatApplication
//
//  Created by hamed on 7/7/23.
//

import Chat
import ChatAppUI
import ChatAppViewModels
import ChatDTO
import ChatModels
import Combine
import SwiftUI

struct ThreadViewCenterToolbar: View {
    @EnvironmentObject var appState: AppState
    var viewModel: ThreadViewModel
    @State private var title: String = ""
    @State private var participantCount: Int?
    @State private var cancelableSet = Set<AnyCancellable>()

    var body: some View {
        VStack(alignment: .center) {
            Text(title)
                .fixedSize()
                .font(.iransansBoldSubheadline)
            if appState.connectionStatus != .connected {
                ConnectionStatusToolbar()
            } else if let signalMessageText = viewModel.signalMessageText {
                Text(signalMessageText)
                    .foregroundColor(.textBlueColor)
                    .font(.iransansCaption2)
            } else if let participantsCount = participantCount {
                Text("Members \(participantsCount)")
                    .fixedSize()
                    .foregroundColor(Color.gray)
                    .font(.iransansFootnote)
            }
        }
        .onChange(of: viewModel.thread.computedTitle) { newValue in
            title = newValue
        }
        .onChange(of: viewModel.thread.participantCount) { newValue in
            participantCount = newValue
        }
        .onAppear {
            participantCount = viewModel.thread.participantCount
            title = viewModel.thread.computedTitle
            NotificationCenter.default.publisher(for: .thread)
                .compactMap { $0.object as? ParticipantEventTypes }
                .sink { event in
                    if case let .added(response) = event {
                        withAnimation {
                            participantCount = (participantCount ?? 0) + (response.result?.count ?? 0)
                        }
                    }

                    if case let .deleted(response) = event {
                        withAnimation {
                            participantCount = max(0, (participantCount ?? 0) - (response.result?.count ?? 0))
                        }
                    }
                }
                .store(in: &cancelableSet)

            NotificationCenter.default.publisher(for: .thread)
                .compactMap { $0.object as? ThreadEventTypes }
                .sink { event in
                    if case let .updatedInfo(response) = event {
                        withAnimation {
                            title = response.result?.computedTitle ?? ""
                        }
                    }
                }
                .store(in: &cancelableSet)
        }
    }
}

struct ThreadViewCenterToolbar_Previews: PreviewProvider {
    static var previews: some View {
        ThreadViewCenterToolbar(viewModel: ThreadViewModel(thread: Conversation()))
    }
}
