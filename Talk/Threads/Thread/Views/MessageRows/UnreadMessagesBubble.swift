//
//  UnreadMessagesBubble.swift
//  Talk
//
//  Created by hamed on 7/6/23.
//

import SwiftUI

struct UnreadMessagesBubble: View {
    var body: some View {
        Text("Messages.unreadMessages")
            .font(.iransansCaption)
            .padding(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            .background(Color.App.hint)
            .clipShape(RoundedRectangle(cornerRadius:(16)))
            .foregroundColor(Color.App.white)
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
