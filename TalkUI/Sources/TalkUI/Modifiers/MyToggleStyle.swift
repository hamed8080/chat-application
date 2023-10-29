//
//  MyToggleStyle.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 11/30/21.
//

import SwiftUI

public struct MyToggleStyle: ToggleStyle {
    public init() {}
    public func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .background(configuration.isOn ? Color.App.gray1.opacity(0.3) : Color.clear)
            .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
            .padding([.top, .bottom], 16)
    }
}

struct MyToggleStyle_Previews: PreviewProvider {
    static var previews: some View {
        Toggle("TEST", isOn: .constant(false))
            .toggleStyle(MyToggleStyle())
    }
}
