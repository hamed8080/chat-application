//
//  CallParticipant+.swift
//  ChatApplication
//
//  Created by hamed on 12/4/22.
//

import ChatModels
import Foundation
import SwiftUI

public extension CallParticipant {
    var title: String? {
        participant?.name ?? participant?.firstName ?? participant?.lastName ?? participant?.email ?? participant?.username
    }

    var callStatusStringColor: Color {
        switch callStatus {
        case .requested:
            return .clear
        case .canceled:
            return .red
        case .miss:
            return .red
        case .declined:
            return .red
        case .accepted:
            return .green
        case .started:
            return .green
        case .ended:
            return .clear
        case .leave:
            return .red
        case .unknown:
            return .clear
        case .none:
            return .clear
        }
    }

    var callStatusString: String? {
        switch callStatus {
        case .requested:
            return nil
        case .canceled:
            return "Rejected"
        case .miss:
            return "Didn't answer"
        case .declined:
            return "Declined"
        case .accepted:
            return nil
        case .started:
            return nil
        case .ended:
            return nil
        case .leave:
            return "Left"
        case .unknown:
            return nil
        case .none:
            return nil
        }
    }

    var canRecall: Bool {
        let statuses: [CallStatus] = [.canceled, .declined, .ended, .leave, .miss]
        guard let callStatus = callStatus else { return false }
        return statuses.contains(callStatus)
    }
}
