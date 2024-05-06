//
//  P2PThreadLastSeenView.swift
//  Talk
//
//  Created by hamed on 5/6/24.
//

import SwiftUI
import TalkModels
import TalkViewModels
import ChatModels
import ChatDTO

struct P2PThreadLastSeenView : View {
    let thread: Conversation
    @State private var lastSeen = ""
    private var p2pPartnerFinderVM = FindPartnerParticipantViewModel()

    init(thread: Conversation) {
        self.thread = thread
    }

    var body: some View {
        Text(lastSeen)
            .fixedSize()
            .foregroundColor(Color.App.toolbarSecondaryText)
            .font(.iransansFootnote)
            .onAppear {
                if canGetParticipant {
                    getPartner()
                } else if thread.id == LocalId.emptyThread.rawValue {
                    setUnknown()
                }
            }
    }

    private var canGetParticipant: Bool {
        if thread.group == true { return false }
        return lastSeen.isEmpty && thread.id != LocalId.emptyThread.rawValue
    }

    private func getPartner() {
        guard let threadId = thread.id else { return }
        p2pPartnerFinderVM.findPartnerBy(threadId: threadId) { partner in
            if let partner = partner {
                processResponse(partner)
            }
        }
    }

    private func processResponse(_ partner: Participant) {
        guard let lastSeen = partner.notSeenDuration?.lastSeenString else { return }
        let localized = "Contacts.lastVisited".bundleLocalized()
        let formatted = String(format: localized, lastSeen)
        self.lastSeen = formatted
    }

    private func setUnknown() {
        let lastSeen = "Contacts.lastSeen.unknown".bundleLocalized()
        let localized = "Contacts.lastVisited".bundleLocalized()
        let formatted = String(format: localized, lastSeen)
        self.lastSeen = formatted
    }
}

struct P2PThreadLastSeenView_Previews: PreviewProvider {
    static var previews: some View {
        P2PThreadLastSeenView(thread: .init())
    }
}
