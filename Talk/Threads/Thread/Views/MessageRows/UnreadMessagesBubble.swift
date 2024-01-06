//
//  UnreadMessagesBubble.swift
//  Talk
//
//  Created by hamed on 7/6/23.
//

import SwiftUI

struct UnreadMessagesBubble: View {
    var body: some View {
        HStack {
            Text("Messages.unreadMessages")
                .font(.iransansCaption)
                .padding(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .clipShape(RoundedRectangle(cornerRadius:(16)))
                .foregroundColor(Color.App.accent)
                .frame(minWidth: 0, maxWidth: .infinity)
                .multilineTextAlignment(.center)
        }
        .background(Color.App.bgPrimary)
    }
}

struct UnreadMessagesBubble_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Image("chat_bg")
                .resizable()
                .scaledToFill()
            HStack {
                UnreadMessagesBubble()
            }
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(.ultraThinMaterial.opacity(0.6))
        }
    }
}
