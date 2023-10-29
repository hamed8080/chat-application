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
            .padding([.leading, .trailing], 16)
            .padding([.bottom, .top], 6)
            .background(Color.App.hint)
            .cornerRadius(16)
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
