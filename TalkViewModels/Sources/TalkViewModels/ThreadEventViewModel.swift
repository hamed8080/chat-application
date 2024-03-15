//
//  ThreadEventViewModel
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Foundation
import ChatModels
import ChatDTO

public final class ThreadEventViewModel: ObservableObject {
    @Published public var isShowingEvent: Bool = false
    public var threadId: Int
    public var smt: SMT?
    private var lastEventTime = Date()
    public init(threadId: Int) {
        self.threadId = threadId
    }

    public func startEventTimer(_ event: SystemEventMessageModel) {
        if isShowingEvent == false {
            lastEventTime = Date()
            isShowingEvent = true
            self.smt = event.smt
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
