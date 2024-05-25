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
    @StateObject var eventVM: ThreadEventViewModel
    private let threadPublisher = NotificationCenter.thread.publisher(for: .thread).compactMap { $0.object as? ThreadEventTypes }
    private let participantPublisher = NotificationCenter.participant.publisher(for: .participant).compactMap { $0.object as? ParticipantEventTypes }
    private let eventPublisher = NotificationCenter.system.publisher(for: .system).compactMap { $0.object as? SystemEventTypes }
    private var thread: Conversation { viewModel.thread }

    init(viewModel: ThreadViewModel) {
        let threadId = viewModel.threadId
        self.viewModel = viewModel
        self._eventVM = StateObject(wrappedValue: .init(threadId: threadId))
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            threadTitleButton
            ConnectionStatusToolbar()
                .frame(height: showConnectionStatus ? nil : 0)
                .opacity(showConnectionStatus ? 1 : 0)
                .scaleEffect(x: showConnectionStatus ? 1 : 0, y: showConnectionStatus ? 1 : 0, anchor: .center)
                .clipped()
            Text(signalMessageText)
                .foregroundColor(Color.App.toolbarSecondaryText)
                .font(.iransansBoldCaption2)
                .frame(height: showSignaling ? nil : 0)
                .opacity(showSignaling ? 1 : 0)
                .scaleEffect(x: showSignaling ? 1 : 0, y: showSignaling ? 1 : 0, anchor: .center)
                .clipped()
            Text(verbatim: numberOfParticipants)
                .foregroundColor(Color.App.toolbarSecondaryText)
                .font(.iransansFootnote)
                .frame(height: showParticipantCount ? nil : 0)
                .opacity(showParticipantCount ? 1 : 0)
                .scaleEffect(x: showParticipantCount ? 1 : 0, y: showParticipantCount ? 1 : 0, anchor: .center)
                .clipped()
            P2PThreadLastSeenView(thread: thread)
                .frame(height: canShowLastSeen ? nil : 0)
                .opacity(canShowLastSeen ? 1 : 0)
                .scaleEffect(x: canShowLastSeen ? 1 : 0, y: canShowLastSeen ? 1 : 0, anchor: .center)
                .clipped()
        }
        .animation(.easeInOut, value: participantsCount)
        .animation(.easeInOut, value: showSignaling)
        .animation(.easeInOut, value: showConnectionStatus)
        .animation(.easeInOut, value: title)
        .onChange(of: viewModel.thread.computedTitle) { newValue in
            title = newValue
        }
//        .onReceive(viewModel.objectWillChange) { newValue in
//            participantsCount = viewModel.thread.participantCount ?? 0
//        }
        .onReceive(threadPublisher) { event in
            onThreadEvent(event)
        }
        .onReceive(participantPublisher) { event in
            onParticipantEvent(event)
        }
        .onReceive(eventPublisher) { event in
            onThreadSystemEvent(event)
        }
        .onAppear {
            participantsCount = viewModel.thread.participantCount
            title = viewModel.thread.computedTitle
        }
    }

    private var threadTitleButton: some View {
        Button {
            appState.objectsContainer.navVM.appendThreadDetail(threadViewModel: viewModel)
        } label: {
            Text(title)
                .font(.iransansBoldBody)
                .foregroundStyle(Color.App.white)
                .padding(.horizontal, thread.isTalk ? 0 : 48) // for super large titles we need to cut the text the best way for this is add a horizontal padding

            if thread.isTalk {
                Image("ic_approved")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .offset(x: -4)
            }
        }
        .buttonStyle(.plain)
    }

    private var showConnectionStatus: Bool {
        appState.connectionStatus != .connected
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

    func onThreadSystemEvent(_ event: SystemEventTypes) {
        switch event {
        case .systemMessage(let chatResponse):
            guard let result = chatResponse.result else { return }
            eventVM.startEventTimer(result)
        default:
            break
        }
    }

    private var showSignaling: Bool {
        if showConnectionStatus { return false }
        return !signalMessageText.isEmpty
    }

    private var signalMessageText: String {
        return eventVM.smt?.titleAndIcon?.title ?? ""
    }

    private var showParticipantCount: Bool {
        if showConnectionStatus { return false }
        return !numberOfParticipants.isEmpty
    }

    private var numberOfParticipants: String {
        if thread.group == true, let participantsCount = participantsCount?.localNumber(locale: Language.preferredLocale) {
            let localizedLabel = String(localized: "Thread.Toolbar.participants", bundle: Language.preferedBundle)
            return "\(participantsCount) \(localizedLabel)"
        } else {
            return ""
        }
    }

    private var canShowLastSeen: Bool {
        if showSignaling { return false }
        return (thread.group == nil || thread.group == false) && thread.type != .selfThread
    }
}

struct ThreadViewCenterToolbar_Previews: PreviewProvider {
    static var previews: some View {
        ThreadViewCenterToolbar(viewModel: ThreadViewModel(thread: Conversation()))
    }
}
