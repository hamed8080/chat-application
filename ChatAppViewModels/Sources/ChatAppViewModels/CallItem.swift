//
//  CallItem.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 10/16/21.
//

import Foundation
class CallItem: ObservableObject {
    let uuid: UUID
    let isOutgoing: Bool
    var handle: String?

    // MARK: - Call State Properties

    @Published var connectingDate: Date? {
        didSet {
            stateDidChange?()
            hasStartedConnectingDidChange?()
        }
    }

    @Published var connectDate: Date? {
        didSet {
            stateDidChange?()
            hasConnectedDidChange?()
        }
    }

    @Published var endDate: Date? {
        didSet {
            stateDidChange?()
            hasEndedDidChange?()
        }
    }

    @Published var isOnHold = false {
        didSet {
            stateDidChange?()
        }
    }

    // MARK: - State Change Callbacks

    var stateDidChange: (() -> Void)?
    var hasStartedConnectingDidChange: (() -> Void)?
    var hasConnectedDidChange: (() -> Void)?
    var hasEndedDidChange: (() -> Void)?

    init(uuid: UUID, isOutgoing: Bool = false) {
        self.uuid = uuid
        self.isOutgoing = isOutgoing
    }

    // MARK: - Derived Properties

    var hasStartedConnecting: Bool {
        get {
            connectingDate != nil
        }
        set {
            connectingDate = newValue ? Date() : nil
        }
    }

    var hasConnected: Bool {
        get {
            connectDate != nil
        }
        set {
            connectDate = newValue ? Date() : nil
        }
    }

    var hasEnded: Bool {
        get {
            endDate != nil
        }
        set {
            endDate = newValue ? Date() : nil
        }
    }

    var duration: TimeInterval {
        guard let connectDate = connectDate else {
            return 0
        }

        return Date().timeIntervalSince(connectDate)
    }

    // MARK: - Actions

    /// Starts a new call with the specified completion handler to indicate if the call was successful.
    /// - Parameter completion: A closure to execute when the call attempt is made, to indicate if the call was successful.
    func startCall(completion: ((_ success: Bool) -> Void)?) {
        // Simulate the call starting successfully.
        completion?(true)

        /*
         Simulate the "started connecting" and "connected" states using artificial delays,
         because the example app is not backed by a real network service.
         */
        DispatchQueue.main.asyncAfter(wallDeadline: DispatchWallTime.now() + 3) {
            self.hasStartedConnecting = true

            DispatchQueue.main.asyncAfter(wallDeadline: DispatchWallTime.now() + 1.5) {
                self.hasConnected = true
            }
        }
    }

    /// Answers an incoming call.
    func answerIncomingCall() {
        /*
         Simulate the answer is connected immediately,
         because the example app is not backed by a real network service.
         */
        hasConnected = true
    }

    /// Ends the current call.
    func endCall() {
        /*
         Simulate the end takes effect immediately,
         because the example app is not backed by a real network service.
         */
        hasEnded = true
    }
}
