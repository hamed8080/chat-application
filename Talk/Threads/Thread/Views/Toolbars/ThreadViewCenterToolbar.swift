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
    private let threadPublisher = NotificationCenter.thread.publisher(for: .thread).compactMap { $0.object as? ThreadEventTypes }
    private let participantPublisher = NotificationCenter.participant.publisher(for: .participant).compactMap { $0.object as? ParticipantEventTypes }
    private var thread: Conversation { viewModel.thread }
    private var partner: Participant? { thread.participants?.first(where: {$0.id == thread.partner }) }

    var body: some View {
        VStack(alignment: .center, spacing: appState.connectionStatus == .connected ? 4 : 0) {
            Button {
                appState.objectsContainer.navVM.appendThreadDetail(threadViewModel: viewModel)
            } label: {
                Text(title)
                    .font(.iransansBoldBody)
                    .foregroundStyle(Color.App.white)
            }
            .buttonStyle(.plain)

            if appState.connectionStatus != .connected {
                ConnectionStatusToolbar()
            } else if let signalMessageText = viewModel.signalMessageText {
                Text(signalMessageText)
                    .foregroundColor(Color.App.toolbarSecondaryText)
                    .font(.iransansCaption2)
            } else if thread.group == true, let participantsCount = participantsCount?.localNumber(locale: Language.preferredLocale) {
                let localizedLabel = String(localized: "Thread.Toolbar.participants")
                Text("\(localizedLabel) \(participantsCount)")
                    .fixedSize()
                    .foregroundColor(Color.App.toolbarSecondaryText)
                    .font(.iransansFootnote)
            } else if thread.group == nil || thread.group == false, thread.type != .selfThread {
                P2PThreadLastSeenView(thread: thread)
            }
        }
        .animation(.easeInOut, value: appState.connectionStatus == .connected)
        .animation(.easeInOut, value: title)
        .animation(.easeInOut, value: viewModel.signalMessageText != nil)
        .onChange(of: viewModel.thread.computedTitle) { newValue in
            title = newValue
        }
        .onReceive(viewModel.objectWillChange) { newValue in
            participantsCount = viewModel.thread.participantCount ?? 0
        }
        .onReceive(threadPublisher) { event in
            onThreadEvent(event)
        }
        .onReceive(participantPublisher) { event in
            onParticipantEvent(event)
        }
        .onAppear {
            participantsCount = viewModel.thread.participantCount
            title = viewModel.thread.computedTitle
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

struct P2PThreadLastSeenView : View {
    let thread: Conversation
    @State private var lastSeen = ""

    var body: some View {
        let localized = String(localized: .init("Contacts.lastVisited"))
        let formatted = String(format: localized, lastSeen)
        Text(lastSeen.isEmpty ? "" : formatted)
            .fixedSize()
            .foregroundColor(Color.App.toolbarSecondaryText)
            .font(.iransansFootnote)
            .onAppear {
                if lastSeen.isEmpty {
                    ChatManager.activeInstance?.conversation.participant.get(.init(threadId: thread.id ?? -1))
                }
            }
            .onReceive(NotificationCenter.participant.publisher(for: .participant)) { notif in
                guard
                    let event = notif.object as? ParticipantEventTypes,
                    case let .participants(response) = event,
                    let lastSeen = response.result?.first(where: {$0.id == thread.partner})?.notSeenDuration?.localFormattedTime
                else { return }
                self.lastSeen = lastSeen
            }
    }
}

struct ThreadViewCenterToolbar_Previews: PreviewProvider {
    static var previews: some View {
        ThreadViewCenterToolbar(viewModel: ThreadViewModel(thread: Conversation()))
    }
}
