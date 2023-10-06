//
//  NavigationBackButton.swift
//  Talk
//
//  Created by hamed on 10/5/23.
//

import SwiftUI
import TalkViewModels

public struct NavigationBackButton: View {
    @EnvironmentObject var navViewModel: NavigationModel
    @Environment(\.dismiss) var dismiss
    let action: (() -> ())?

    public init(action: (() -> Void)? = nil) {        
        self.action = action
    }

    public var body: some View {
        Button {
            action?()
            dismiss()
        } label : {
            HStack {
                Image(systemName: "chevron.backward")
                let localized = String(localized: .init(navViewModel.previousTitle))
                let maxLength = UIDevice.current.userInterfaceIdiom == .pad ? 35 : 15
                let string = String(localized.prefix(maxLength))
                Text(string)
                    .font(.iransansSubtitle)
            }
        }
    }
}

struct NavigationBackButton_Previews: PreviewProvider {
    static var previews: some View {
        NavigationBackButton {

        }
    }
}
