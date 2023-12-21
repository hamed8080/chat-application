//
//  LogRow.swift
//  Talk
//
//  Created by hamed on 6/27/22.
//

import Chat
import Logger
import SwiftUI
import TalkUI

struct LogRow: View {
    var log: Log
    var color: Color {
        let type = log.type
        if type == .internalLog {
            return Color.App.primary
        } else if type == .received {
            return Color.App.red
        } else {
            return Color.App.green
        }
    }

    static var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .full
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()

    var body: some View {
        ZStack(alignment: .leading) {
            color.opacity(0.2)
            VStack (alignment: .leading){
                HStack {
                    Text(verbatim: "\(log.time?.millisecondsSince1970 ?? 0)")
                        .font(.iransansCaption)
                    Text(verbatim: "\(LogRow.formatter.string(from: log.time ?? .now))")
                        .font(.iransansCaption)
                }
                Text("\(log.message ?? "")")
                    .font(.iransansCaption)
            }
            .padding()
        }
        .environment(\.layoutDirection, .leftToRight)
        .overlay(alignment: .bottom) {
            Color
                .App
                .gray1
                .opacity(0.5)
                .frame(height: 1)
        }
        .textSelection(.enabled)
    }
}

struct LogRow_Previews: PreviewProvider {
    static var log: Log {
        Log(time: Date(), message: "", level: .error, id: UUID(), type: .internalLog, userInfo: [:])
    }

    static var previews: some View {
        LogRow(log: log)
    }
}
