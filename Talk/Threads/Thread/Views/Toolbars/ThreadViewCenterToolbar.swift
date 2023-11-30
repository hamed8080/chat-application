//
//  ThreadViewCenterToolbar.swift
//  Talk
//
//  Created by hamed on 7/7/23.
//

import Chat
import ChatDTO
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels

struct ThreadViewCenterToolbar: View {
    @EnvironmentObject var appState: AppState
    var viewModel: ThreadViewModel
    @State private var title: String = ""
    @State private var participantsCount: Int?
    private let participantPublisher = NotificationCenter.default.publisher(for: .participant).compactMap { $0.object as? ParticipantEventTypes }
    private let threadPublisher = NotificationCenter.default.publisher(for: .thread).compactMap { $0.object as? ThreadEventTypes }

    var body: some View {
        VStack(alignment: .center) {
            Button {
                appState.objectsContainer.navVM.append(threadDetail: viewModel.thread)
            } label: {
                Text(title)
                    .font(.iransansBoldBody)
            }
            .buttonStyle(.plain)

            if appState.connectionStatus != .connected {
                ConnectionStatusToolbar()
            } else if let signalMessageText = viewModel.signalMessageText {
                Text(signalMessageText)
                    .foregroundColor(Color.App.blue)
                    .font(.iransansCaption2)
            } else if viewModel.thread.group == true, let participantsCount = participantsCount?.localNumber(locale: Language.preferredLocale) {
                let localizedLabel = String(localized: "Thread.Toolbar.participants")
                Text("\(localizedLabel) \(participantsCount)")
                    .fixedSize()
                    .foregroundColor(Color.App.gray1)
                    .font(.iransansFootnote)
            }
        }
        .onChange(of: viewModel.thread.computedTitle) { newValue in
            title = newValue
        }
        .onChange(of: viewModel.thread.participantCount) { newValue in
            participantsCount = newValue
        }
        .onReceive(participantPublisher) { event in
            if case let .added(response) = event {
                withAnimation {
                    participantsCount = (participantsCount ?? 0) + (response.result?.count ?? 0)
                }
            }

            if case let .deleted(response) = event {
                withAnimation {
                    participantsCount = max(0, (participantsCount ?? 0) - (response.result?.count ?? 0))
                }
            }
        }
        .onReceive(threadPublisher) { event in
            if case let .updatedInfo(response) = event {
                withAnimation {
                    title = response.result?.computedTitle ?? ""
                }
            }
        }
        .onAppear {
            participantsCount = viewModel.thread.participantCount
            title = viewModel.thread.computedTitle
        }
    }
}

struct ThreadViewCenterToolbar_Previews: PreviewProvider {
    static var previews: some View {
        ThreadViewCenterToolbar(viewModel: ThreadViewModel(thread: Conversation()))
    }
}
