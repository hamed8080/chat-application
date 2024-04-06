//
//  HistoryScrollDelegate.swift
//  Talk
//
//  Created by hamed on 3/14/24.
//

import Foundation
import UIKit

public protocol HistoryScrollDelegate: AnyObject {
    func scrollTo(index: IndexPath, position: UITableView.ScrollPosition, animate: Bool)
    func scrollTo(uniqueId: String, position: UITableView.ScrollPosition, animate: Bool)
    func reload()
    func relaod(at: IndexPath)
    func reconfig(at: IndexPath)
    func insertd(at: IndexPath)
    func insertd(at: [IndexPath])
    func inserted(_ sections: IndexSet, _ rows: [IndexPath])
    func remove(at: IndexPath)
    func remove(at: [IndexPath])
}

public protocol UnreadCountDelegate {
    func onUnreadCountChanged()
}

public protocol ChangeUnreadMentionsDelegate {
    func onChangeUnreadMentions()
}

public protocol ChangeSelectionDelegate {
    func setSelection(_ value: Bool)
    func updateCount()
}

public protocol LastMessageAppearedDelegate {
    func lastMessageAppeared(_ appeared: Bool)
}

public protocol SheetsDelegate {
    func openForwardPicker()
}

public protocol ThreadViewDelegate: AnyObject, UnreadCountDelegate, ChangeUnreadMentionsDelegate, ChangeSelectionDelegate, LastMessageAppearedDelegate, SheetsDelegate, HistoryScrollDelegate {

}
