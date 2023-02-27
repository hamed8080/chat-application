//
//  ThreadEventViewModel
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Combine
import FanapPodChatSDK
import Foundation

class ThreadEventViewModel: ObservableObject {
    @Published var isShowingEvent: Bool = false
    var threadId: Int?
    var smt: SMT?
    private(set) var cancellableSet: Set<AnyCancellable> = []
    init() {}

    func setThread(threadId: Int) {
        self.threadId = threadId
        setupNotificationObservers()
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: .systemMessageEventNotificationName)
            .compactMap { $0.object as? SystemEventTypes }
            .sink { [weak self] systemMessageEvent in
                self?.startEventTimer(systemMessageEvent)
            }
            .store(in: &cancellableSet)
    }

    private var lastEventTime = Date()

    private func startEventTimer(_ event: SystemEventTypes) {
        if case let .systemMessage(response) = event, let smt = response.result?.smt, isShowingEvent == false, threadId == response.subjectId {
            lastEventTime = Date()
            isShowingEvent = true
            self.smt = smt
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
                if let self = self, self.lastEventTime.advanced(by: 1) < Date() {
                    timer.invalidate()
                    self.isShowingEvent = false
                    self.smt = nil
                }
            }
        } else {
            lastEventTime = Date()
        }
    }
}
