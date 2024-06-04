//
//  MutableMessageStatusView.swift
//  Talk
//
//  Created by hamed on 5/30/24.
//

import Foundation
import Chat
import SwiftUI
import TalkViewModels
import TalkUI

struct MutableMessageStatusView: View {
    let status: (icon: UIImage, fgColor: Color)?
    let isSelected: Bool

    var body: some View {
        if let status = status {
            Image(uiImage: status.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .foregroundColor(isSelected ? Color.App.white : status.fgColor)
                .font(.subheadline)
                .offset(y: -2)
                .id(status.icon)
        }
    }
}
