//
//  LazyListViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import Combine

@MainActor
public class LazyListViewModel: ObservableObject {
    @Published public private(set) var isLoading: Bool = false
    public var count: Int = 15
    public var offset: Int = 0
    private var hasNext = true

    nonisolated public init() {}

    public func setLoading(_ value: Bool) {
        isLoading = value
    }

    public func canLoadMore() async -> Bool {
        if isLoading || !hasNext { return false }
        return true
    }

    public func isLoadingStatus() -> Bool {
        return isLoading
    }

    public func prepareForLoadMore() {
        if !hasNext { return }
        offset = offset + count
    }

    public func setHasNext(_ value: Bool) {
        hasNext = value
    }

    public func reset() {
        hasNext = true
        offset = 0
        isLoading = false
    }
}
