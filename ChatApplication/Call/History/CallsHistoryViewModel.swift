//
//  CallsHistoryViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Combine
import FanapPodChatSDK
import Foundation

class CallsHistoryViewModel: ObservableObject {
    @Published var isLoading = false

    @Published private(set) var model = CallsHistoryModel()

    private(set) var connectionStatusCancelable: AnyCancellable?

    init() {
        connectionStatusCancelable = AppState.shared.$connectionStatus.sink { status in
            if self.model.calls.count == 0, status == .connected {
                self.getCallsHistory()
            }
        }
    }

    func getCallsHistory() {
        ChatManager.activeInstance.callsHistory(.init(count: model.count, offset: model.offset)) { [weak self] response in
            if let calls = response.result {
                self?.model.setCalls(calls: calls)
                self?.model.setHasNext(response.pagination?.hasNext ?? false)
            }
        }
    }

    func loadMore() {
        if !model.hasNext || isLoading { return }
        isLoading = true
        model.preparePaginiation()
        ChatManager.activeInstance.callsHistory(.init(count: model.count, offset: model.offset)) { [weak self] response in
            if let calls = response.result {
                self?.model.appendCalls(calls: calls)
                self?.isLoading = false
            }
        }
    }

    func refresh() {
        clear()
        getCallsHistory()
    }

    func clear() {
        model.clear()
    }

    func setupPreview() {
        model.setupPreview()
    }
}
