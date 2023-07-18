//
//  ConnectionStatusToolbar.swift
//  ChatApplication
//
//  Created by hamed on 10/21/22.
//

import SwiftUI
import ChatAppModels
import ChatAppViewModels

public struct ConnectionStatusToolbar: View {
    @State var connectionStatus: ConnectionStatus
    @EnvironmentObject var appstate: AppState

    public init(connectionStatus: ConnectionStatus = .connecting) {
        self.connectionStatus = connectionStatus
    }

    @ViewBuilder
    public var body: some View {
        if connectionStatus != .connected {
            Text("\(connectionStatus.stringValue) ...")
                .font(.iransansBoldBody)
                .foregroundColor(.textBlueColor)
                .onReceive(appstate.$connectionStatus) { newSate in
                    self.connectionStatus = newSate
                }
        } else {
            EmptyView()
                .hidden()
                .frame(width: 0, height: 0)
                .onReceive(appstate.$connectionStatus) { newSate in
                    self.connectionStatus = newSate
                }
        }
    }
}

struct ConnectionStatusToolbar_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionStatusToolbar()
    }
}
