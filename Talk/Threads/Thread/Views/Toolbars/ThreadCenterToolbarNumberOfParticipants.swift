//
//  ThreadCenterToolbarNumberOfParticipants.swift
//  Talk
//
//  Created by hamed on 5/29/24.
//

import Foundation
import SwiftUI
import TalkViewModels
import TalkModels
//
//struct ThreadCenterToolbarNumberOfParticipants: View {
//    @EnvironmentObject var viewModel: ThreadViewModel
//    @EnvironmentObject var appState: AppState
//
//    var body: some View {
//        Text(verbatim: numberOfParticipants)
//            .foregroundColor(Color.App.toolbarSecondaryText)
//            .font(.iransansFootnote)
//            .frame(height: showParticipantCount ? nil : 0)
//            .opacity(showParticipantCount ? 1 : 0)
//            .scaleEffect(x: showParticipantCount ? 1 : 0, y: showParticipantCount ? 1 : 0, anchor: .center)
//            .clipped()
//            .animation(.easeInOut, value: numberOfParticipants)
//    }
//
//    private var numberOfParticipants: String {
//        if viewModel.thread.group == true, let participantsCount = viewModel.thread.participantCount?.localNumber(locale: Language.preferredLocale) {
//            let localizedLabel = String(localized: "Thread.Toolbar.participants", bundle: Language.preferedBundle)
//            return "\(participantsCount) \(localizedLabel)"
//        } else {
//            return ""
//        }
//    }
//
//    private var showParticipantCount: Bool {
//        if showConnectionStatus { return false }
//        return !numberOfParticipants.isEmpty
//    }
//
//    private var showConnectionStatus: Bool {
//        appState.connectionStatus != .connected
//    }
//}
