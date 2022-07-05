//
//  SearchMessageRow.swift
//  ChatApplication
//
//  Created by hamed on 6/21/22.
//

import SwiftUI
import FanapPodChatSDK

struct SearchMessageRow: View {
    
    let message:Message
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 16){
            
            Text(((message.message?.isEmpty ?? true) == true ? message.metaData?.name : message.message) ?? "")
                .multilineTextAlignment(message.message?.isEnglishString == true ? .leading : .trailing)
                .padding(.top, 8)
                .padding([.leading, .trailing , .top])
                .font(Font(UIFont.systemFont(ofSize: 18)))
                .fixedSize(horizontal: false, vertical: true)
            
            if let time = message.time, let date = Date(timeIntervalSince1970: TimeInterval(time) / 1000) {
                HStack{
                    if message.message?.isEnglishString == true{
                        Spacer()
                    }
                    Text("\(date.getTime())")
                        .foregroundColor(Color(named: "dark_green").opacity(0.8))
                        .font(.subheadline)
                    if message.message?.isEnglishString == false{
                        Spacer()
                    }
                }
            }
        }
        .padding(8)
    }
}

struct SearchMessageRow_Previews: PreviewProvider {
    static var previews: some View {
        SearchMessageRow(message: MockData.message)
    }
}
