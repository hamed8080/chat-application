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
        } else if #available(iOS 14.0, *) { // iOS 14
            self
                .accentColor(Color.secondary)
                .onAppear {
                    UITableView.appearance().backgroundColor = UIColor.clear
                }
        } else { // iOS 13
            listStyle(.plain)
                .onAppear {
                    UITableView.appearance().separatorStyle = .none
                }
        }
    }
}
