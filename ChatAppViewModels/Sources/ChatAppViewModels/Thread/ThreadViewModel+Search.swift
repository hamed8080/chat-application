//
//  ThreadViewModel+Search.swift
//  ChatApplication
//
//  Created by hamed on 10/22/22.
//

import Foundation
import Chat
import ChatCore
import ChatDTO
import ChatModels

extension ThreadViewModel {
    public func searchInsideThread(text: String, offset: Int = 0) {
        searchTextTimer?.invalidate()
        searchTextTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] _ in
            self?.doSearch(text: text, offset: offset)
        }
    }

    public func doSearch(text: String, offset: Int = 0) {
        isInSearchMode = text.count >= 2
        animatableObjectWillChange()
        guard text.count >= 2 else { return }
        let req = GetHistoryRequest(threadId: threadId, count: 50, offset: searchOffset, query: "\(text)")
        requests["SEARCH-\(req.uniqueId)"] = req
        ChatManager.activeInstance?.message.history(req)
    }

    func onSearch(_ response: ChatResponse<[Message]>) {
        guard let uniqueId = response.uniqueId, requests["SEARCH-\(uniqueId)"] != nil else { return }
        searchedMessages.removeAll()
        response.result?.forEach { message in
            if !(searchedMessages.contains(where: { $0.id == message.id })) {
                searchedMessages.append(message)
            }
        }
        animatableObjectWillChange()
        requests.removeValue(forKey: "SEARCH-\(uniqueId)")
    }
}
