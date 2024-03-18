//
//  HistoryScrollDelegate.swift
//  Talk
//
//  Created by hamed on 3/14/24.
//

import Foundation
import UIKit

public protocol HistoryScrollDelegate: AnyObject {
    func scrollTo(index: IndexPath)
    func scrollTo(uniqueId: String)
    func reload()
    func relaod(at: IndexPath)
    func insertd(at: IndexPath)
    func insertd(at: [IndexPath])
    func inserted(_ sections: IndexSet, _ rows: [IndexPath])
    func remove(at: IndexPath)
    func remove(at: [IndexPath])
}
