//
//  ObservableObject.Name+.swift
//  ChatApplication
//
//  Created by hamed on 2/27/23.
//

import Foundation
import Combine
import SwiftUI

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
