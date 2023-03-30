//
//  LogRow.swift
//  ChatApplication
//
//  Created by hamed on 6/27/22.
//

import FanapPodChatSDK
import SwiftUI

struct LogRow: View {
    var log: Log
    var color: Color {
        let log = LogEmitter(rawValue: Int(log.type))
        if log == .internalLog {
            return .orange
        } else if log == .received {
            return .red
        } else {
            return .green
        }
    }

    var body: some View {
        ZStack(alignment: .leading) {
            color.opacity(0.2)
            Text("\(log.log ?? "")")
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
        let req = Log.fetchRequest()
        req.fetchLimit = 1
        let log = (try! PSM.preview.container.viewContext.fetch(req)).first!
        return log
    }

    static var previews: some View {
        LogRow(log: log)
    }
}
