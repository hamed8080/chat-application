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

    var body: some View {
        ZStack(alignment: .leading) {
            (log.received ? Color.red : Color.green).opacity(0.2)
            Text("\(log.json ?? "")")
                .padding()

        }.textSelection(.enabled)
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
