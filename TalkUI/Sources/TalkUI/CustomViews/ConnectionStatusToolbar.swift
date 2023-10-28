//
//  ConnectionStatusToolbar.swift
//  TalkUI
//
//  Created by hamed on 10/21/22.
//

import SwiftUI
import TalkModels
import TalkViewModels

public struct ConnectionStatusToolbar: View {
    @State var connectionStatus: ConnectionStatus
    @EnvironmentObject var appstate: AppState

    public init(connectionStatus: ConnectionStatus = .connecting) {
        self.connectionStatus = connectionStatus
    }

    @ViewBuilder
    public var body: some View {
        if connectionStatus != .connected {
            HStack {
                let localized = String(localized: .init(connectionStatus.stringValue))
                Text(localized)
                    .font(.iransansBoldCaption3)
                    .foregroundColor(.hint)
                    .onReceive(appstate.$connectionStatus) { newSate in
                        if EnvironmentValues.isTalkTest {
                            connectionStatus = newSate
                        } else {
                            if connectionStatus == .unauthorized {
                                connectionStatus = .connecting
                            } else {
                                connectionStatus = newSate
                            }
                        }
                    }
                ThreeDotAnimation()
                    .frame(width: 26, height: 8)
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
