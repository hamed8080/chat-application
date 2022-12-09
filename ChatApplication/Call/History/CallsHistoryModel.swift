//
//  CallsHistoryModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import FanapPodChatSDK
import Foundation

struct CallsHistoryModel {
    private(set) var count = 15
    private(set) var offset = 0
    private(set) var hasNext = false
    private(set) var calls: [Call] = []

    mutating func setHasNext(_ hasNext: Bool) {
        self.hasNext = hasNext
    }

    mutating func preparePaginiation() {
        offset = calls.count
    }

    mutating func setCalls(calls: [Call]) {
        self.calls = calls
    }

    mutating func appendCalls(calls: [Call]) {
        self.calls.append(contentsOf: calls)
    }

    mutating func clear() {
        offset = 0
        count = 15
        hasNext = false
        calls = []
    }
}

extension CallsHistoryModel {
    mutating func setupPreview() {
        let t1 = CallRow_Previews.call
        let t2 = CallRow_Previews.call
        let t3 = CallRow_Previews.call
        appendCalls(calls: [t1, t2, t3])
    }
}
