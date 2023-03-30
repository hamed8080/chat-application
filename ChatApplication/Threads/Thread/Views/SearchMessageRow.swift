//
//  SearchMessageRow.swift
//  ChatApplication
//
//  Created by hamed on 6/21/22.
//

import FanapPodChatSDK
import SwiftUI

struct SearchMessageRow: View {
    let message: Message

    var body: some View {
        VStack(alignment: .trailing, spacing: 16) {
            Text(message.message ?? message.fileMetaData?.name ?? "")
                .multilineTextAlignment(message.message?.isEnglishString == true ? .leading : .trailing)
                .padding(.top, 8)
                .padding([.leading, .trailing, .top])
                .font(Font(UIFont.systemFont(ofSize: 18)))

            if let time = message.time {
                let date = Date(timeIntervalSince1970: TimeInterval(time) / 1000)
                HStack {
                    if message.message?.isEnglishString == true {
                        Spacer()
                    }
                    Text("\(date.formatted(date: .numeric, time: .shortened))")
                        .font(.subheadline)
                    if message.message?.isEnglishString == false {
                        Spacer()
                    }
                }
                .padding()
            }
        }
        .background(.ultraThinMaterial)
        .cornerRadius(8)
        .padding(4)
    }
}

struct SearchMessageRow_Previews: PreviewProvider {
    static var previews: some View {
        SearchMessageRow(message: MockData.message)
    }
}
