//
//  ChatResponse+.swift
//  ChatApplication
//
//  Created by hamed on 12/4/22.
//

import ChatCore

fileprivate var presentableErrors: [Int] = [208]

public extension ChatResponse {
    var isPresentable: Bool { presentableErrors.contains(error?.code ?? 0) }
}
