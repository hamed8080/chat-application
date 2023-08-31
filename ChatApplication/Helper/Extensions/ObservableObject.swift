//
//  ObservableObject.swift
//  ChatApplication
//
//  Created by hamed on 8/31/23.
//

import Foundation
import SwiftUI
import Combine

public extension ObservableObject where Self.ObjectWillChangePublisher == ObservableObjectPublisher {

    func animateObjectWillChange() {
        Task {
            await MainActor.run {
                withAnimation {
                    objectWillChange.send()
                }
            }
        }
    }
}
