//
//  ThreadEventViewModel
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import Foundation
import ChatModels

public final class ThreadEventViewModel: ObservableObject {
    @Published public var isShowingEvent: Bool = false
    public var threadId: Int
    public var smt: SMT?
    public private(set) var cancellableSet: Set<AnyCancellable> = []
    public init(threadId: Int) {
        self.threadId = threadId
        setupNotificationObservers()
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: .system)
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
