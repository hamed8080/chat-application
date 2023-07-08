//
//  UnreadMessagesBubble.swift
//  ChatApplication
//
//  Created by hamed on 7/6/23.
//

import SwiftUI

struct UnreadMessagesBubble: View {
    var body: some View {
        let gradient = Gradient(colors: [
            .purple.opacity(0.8),
            .blue.opacity(0.5),
        ])
        Text("Unread Messages".uppercased())
            .font(.iransansCaption)
            .fontDesign(.rounded)
            .padding([.leading, .trailing], 16)
            .padding([.bottom, .top], 6)
            .background(
                LinearGradient(gradient: gradient,
                               startPoint: .leading,
                               endPoint: .trailing)
                    .background(.thinMaterial.blendMode(.color))
            )
            .cornerRadius(10)
            .foregroundColor(Color.white.opacity(1))
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
