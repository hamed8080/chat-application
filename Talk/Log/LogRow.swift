//
//  LogRow.swift
//  Talk
//
//  Created by hamed on 6/27/22.
//

import Chat
import Logger
import SwiftUI

struct LogRow: View {
    var log: Log
    var color: Color {
        let type = log.type
        if type == .internalLog {
            return Color.main
        } else if type == .received {
            return .red
        } else {
            return .green
        }
    }

    var body: some View {
        ZStack(alignment: .leading) {
            color.opacity(0.2)
            Text("\(log.message ?? "")")
                .font(.iransansCaption)
                .padding()
        }
        .overlay(alignment: .bottom) {
            Color
                .gray
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
