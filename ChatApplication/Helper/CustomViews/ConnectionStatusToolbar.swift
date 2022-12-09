//
//  ConnectionStatusToolbar.swift
//  ChatApplication
//
//  Created by hamed on 10/21/22.
//

import SwiftUI

struct ConnectionStatusToolbar: View {
    @State var connectionStatus: ConnectionStatus = .connecting

    @EnvironmentObject var appstate: AppState

    var body: some View {
        if connectionStatus != .connected {
            Text("\(connectionStatus.stringValue) ...")
                .font(.subheadline.bold())
                .foregroundColor(Color(named: "text_color_blue"))
                .onReceive(appstate.$connectionStatus, perform: { newSate in
                    self.connectionStatus = newSate
                })
        } else {
            EmptyView()
                .hidden()
                .frame(width: 0, height: 0)
                .onReceive(appstate.$connectionStatus, perform: { newSate in
                    self.connectionStatus = newSate
                })
        }
    }
}

struct ConnectionStatusToolbar_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionStatusToolbar()
    }
}
