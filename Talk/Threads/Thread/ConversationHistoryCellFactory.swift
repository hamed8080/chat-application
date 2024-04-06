//
//  ConversationHistoryCellFactory.swift
//  Talk
//
//  Created by hamed on 3/18/24.
//

import Foundation
import UIKit
import TalkViewModels
import TalkModels
import ChatModels

public final class ConversationHistoryCellFactory {
    class func reuse(_ tableView: UITableView, _ indexPath: IndexPath, _ viewModel: ThreadViewModel) -> UITableViewCell {
        guard let viewModel = viewModel.historyVM.viewModelWith(indexPath) else { return UITableViewCell() }
        let message = viewModel.message
        let identifier = cellIdentifier(for: message)
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier.rawValue, for: indexPath)
        let type = message.type
        switch type {
        case .endCall, .startCall:
            let cell = (cell as? CallEventUITableViewCell) ?? CallEventUITableViewCell()
            cell.setValues(viewModel: viewModel)
            return cell
        case .participantJoin, .participantLeft:
            let cell = (cell as? ParticipantsEventUITableViewCell) ?? ParticipantsEventUITableViewCell()
            cell.setValues(viewModel: viewModel)
            return cell
        default:
            if message is UnreadMessageProtocol {
                return UnreadMessageBubbleUITableViewCell()
            } else if let cell = cell as? TextMessageTypeCell, message.isTextMessageType || message.isUnsentMessage || message.isUploadMessage {
                cell.setValues(viewModel: viewModel)
                return cell
            } else {
                return UITableViewCell()
            }
        }
    }

    enum CellTypes: String {
        case call = "CallEventUITableViewCell"
        case message = "TextMessageTypeCell"
        case participants = "ParticipantsEventUITableViewCell"
        case unreadBanner = "UnreadMessageBubbleUITableViewCell"
        case unknown
    }

    private class func cellIdentifier(for message: Message) -> CellTypes {
        let type = message.type
        switch type {
        case .endCall, .startCall:
            return .call
        case .participantJoin, .participantLeft:
            return .participants
        default:
            if message is UnreadMessageProtocol {
                return .unreadBanner
            } else if message.isTextMessageType || message.isUnsentMessage || message.isUploadMessage {
                return .message
            } else {
                return .unknown
            }
        }
    }

    public class func registerCells(_ tableView: UITableView) {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.register(TextMessageTypeCell.self, forCellReuseIdentifier: "TextMessageTypeCell")
        tableView.register(CallEventUITableViewCell.self, forCellReuseIdentifier: "CallEventUITableViewCell")
        tableView.register(ParticipantsEventUITableViewCell.self, forCellReuseIdentifier: "ParticipantsEventUITableViewCell")
        tableView.register(UnreadMessageBubbleUITableViewCell.self, forCellReuseIdentifier: "UnreadMessageBubbleUITableViewCell")
    }
}
