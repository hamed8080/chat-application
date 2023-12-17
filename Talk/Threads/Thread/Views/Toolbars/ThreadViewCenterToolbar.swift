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
    private let publisher = NotificationCenter.default.publisher(for: .chatEvents).compactMap { $0.object as? ChatEventType }

    var body: some View {
        VStack(alignment: .center) {
            Button {
                appState.objectsContainer.navVM.append(threadViewModel: viewModel)
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
        .onReceive(viewModel.objectWillChange) { newValue in
            participantsCount = viewModel.thread.participantCount ?? 0
        }
        .onReceive(publisher) { event in
            onChatEvent(event)
        }
        .onAppear {
            participantsCount = viewModel.thread.participantCount
            title = viewModel.thread.computedTitle
        }
    }

    private func onChatEvent(_ event: ChatEventType) {
        switch event {
        case .thread(let threadEventTypes):
            onThreadEvent(threadEventTypes)
        case .participant(let participantEventTypes):
            onParticipantEvent(participantEventTypes)
        default:
            break
        }
    }

    private func onThreadEvent(_ event: ThreadEventTypes) {
        switch event {
        case .updatedInfo(let response):
            withAnimation {
                title = response.result?.computedTitle ?? ""
            }
        default:
            break
        }
    }

    private func onParticipantEvent(_ event: ParticipantEventTypes) {
        switch event {
        case .deleted(let response):
            withAnimation {
                participantsCount = max(0, (participantsCount ?? 0) - (response.result?.count ?? 0))
            }
        default:
            break
        }
    }
}

struct ThreadViewCenterToolbar_Previews: PreviewProvider {
    static var previews: some View {
        ThreadViewCenterToolbar(viewModel: ThreadViewModel(thread: Conversation()))
    }
}
