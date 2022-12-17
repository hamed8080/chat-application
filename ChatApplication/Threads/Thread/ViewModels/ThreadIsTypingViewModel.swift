//
//  ThreadIsTypingViewModel
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Combine
import FanapPodChatSDK
import Foundation

protocol ThreadIsTypingViewModelProtocol {
    var threadId: Int { get set }
    init(threadId: Int)
    var lastIsTypingTime: Date { get set }
    var isTyping: Bool { get set }
    var cancellableSet: Set<AnyCancellable> { get set }
    func onStartTyping(thread: Int)
}

class ThreadIsTypingViewModel: ObservableObject {
    @Published var isTyping: Bool = false
    var threadId: Int

    init(threadId: Int) {
        self.threadId = threadId
        setupNotificationObservers()
    }

    private(set) var cancellableSet: Set<AnyCancellable> = []
    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: systemMessageEventNotificationName)
            .compactMap { $0.object as? SystemEventTypes }
            .sink { [weak self] systemMessageEvent in
                self?.startTypingTimer(systemMessageEvent)
            }
            .store(in: &cancellableSet)
    }

    private var lastIsTypingTime = Date()

    private func startTypingTimer(_ event: SystemEventTypes) {
        if case let .systemMessage(response) = event, response.result?.smt == .isTyping, isTyping == false, threadId == response.subjectId {
            lastIsTypingTime = Date()
            isTyping = true
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
                if let self = self, self.lastIsTypingTime.advanced(by: 1) < Date() {
                    timer.invalidate()
                    self.isTyping = false
                }
            }
        } else {
            lastIsTypingTime = Date()
        }
    }
}
