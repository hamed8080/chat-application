//
//  CloseButton.swift
//  Talk
//
//  Created by hamed on 11/3/23.
//

import SwiftUI
import TalkUI

struct CloseButton: View {
    let action: (() -> Void)?

    init(action: (() -> Void)? = nil) {
        self.action = action
    }

    var body: some View {
        SendContainerButton(image: "xmark", imageColor: Color.App.gray5) {
            action?()
        }
    }
}

struct CloseButton_Previews: PreviewProvider {
    static var previews: some View {
        CloseButton()
    }
}
