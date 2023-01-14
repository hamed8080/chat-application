//
//  ListModifier.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 9/18/21.
//

import SwiftUI

extension View {
    @ViewBuilder func noSeparators() -> some View {
        if #available(iOS 15.0, *) { // iOS 14
            self.listRowSeparator(.hidden)
        } else { // iOS 13
            listStyle(.plain)
                .onAppear {
                    UITableView.appearance().separatorStyle = .none
                }
        }
    }
}
