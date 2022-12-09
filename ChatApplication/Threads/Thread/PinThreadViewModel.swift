//
//  ArchiveThreadViewModel.swift
//  ChatApplication
//
//  Created by hamed on 11/24/22.
//

import FanapPodChatSDK
import Foundation

protocol ArchiveThreadViewModelProtocol {
    var threadVM: ThreadViewModelProtocol? { get set }
    func toggleArchive()
    func archive(_ threadId: Int)
    func unarchive(_ threadId: Int)
    func onArchiveChanged(_ threadId: Int?, _ uniqueId: String?, _ error: ChatError?)
}

class ArchiveThreadViewModel: ObservableObject, ArchiveThreadViewModelProtocol {
    weak var threadVM: ThreadViewModelProtocol?

    func toggleArchive() {
        guard let threadId = threadVM?.threadId else { return }
        if threadVM?.thread.isArchive == false {
            archive(threadId)
        } else {
            unarchive(threadId)
        }
    }

    func archive(_ threadId: Int) {
        Chat.sharedInstance.archiveThread(.init(subjectId: threadId), onArchiveChanged)
    }

    func unarchive(_ threadId: Int) {
        Chat.sharedInstance.unarchiveThread(.init(subjectId: threadId), onArchiveChanged)
    }

    func onArchiveChanged(_ threadId: Int?, _: String?, _ error: ChatError?) {
        if threadId != nil, error == nil {
            threadVM?.thread.isArchive?.toggle()
            objectWillChange.send()
        }
    }
}
