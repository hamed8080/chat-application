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
        let identifier = viewModel.rowType.cellType
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier.rawValue, for: indexPath)
        switch identifier {
        case .call:
            let cell = (cell as? CallEventUITableViewCell) ?? CallEventUITableViewCell()
            cell.setValues(viewModel: viewModel)
            return cell
        case .partnerMessage:
            let cell = cell as? TextMessagePartnerCellType ?? .init()
            cell.setValues(viewModel: viewModel)
            return cell
        case .meMessage:
            let cell = cell as? TextMessageMeCellType ?? .init()
            cell.setValues(viewModel: viewModel)
            return cell
        case .participants:
            let cell = (cell as? ParticipantsEventUITableViewCell) ?? ParticipantsEventUITableViewCell()
            cell.setValues(viewModel: viewModel)
            return cell
        case .unreadBanner:
            return UnreadMessageBubbleUITableViewCell()
        case .unknown:
            return UITableViewCell()
        }
    }

    public class func registerCells(_ tableView: UITableView) {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: CellTypes.unknown.rawValue)
        tableView.register(TextMessagePartnerCellType.self, forCellReuseIdentifier: CellTypes.partnerMessage.rawValue)
        tableView.register(TextMessageMeCellType.self, forCellReuseIdentifier: CellTypes.meMessage.rawValue)
        tableView.register(CallEventUITableViewCell.self, forCellReuseIdentifier: CellTypes.call.rawValue)
        tableView.register(ParticipantsEventUITableViewCell.self, forCellReuseIdentifier: CellTypes.participants.rawValue)
        tableView.register(UnreadMessageBubbleUITableViewCell.self, forCellReuseIdentifier: CellTypes.unreadBanner.rawValue)
    }
}
