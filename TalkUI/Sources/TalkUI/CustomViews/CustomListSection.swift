//
//  CustomListSection.swift
//  TalkUI
//
//  Created by hamed on 2/20/22.
//

import SwiftUI

public struct CustomListSection<Content>: View where Content: View {
    let header: String?
    let footer: String?
    let content: () -> (Content)

    public init(header: String? = nil, footer: String? = nil, @ViewBuilder content: @escaping () -> (Content)) {
        self.header = header
        self.footer = footer
        self.content = content
    }

    public var body: some View {
        VStack(spacing: 0) {
            if let header {
                Text(header)
                    .font(.iransansCaption2)
            }

            content()

            if let footer {
                Text(footer)
                    .font(.iransansCaption2)
            }
        }
        .background(.ultraThickMaterial)
        .cornerRadius(12, corners: .allCorners)
    }
}

struct CustomListSection_Previews: PreviewProvider {
    static var previews: some View {
        CustomListSection {
            ListSectionButton(imageName: "trash", title: "Delete", color: .red)
            ListSectionButton(imageName: "plus", title: "Add Contact", color: .blue)
        }
    }
}
