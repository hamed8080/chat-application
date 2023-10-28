//
//  ListSectionButton.swift
//  TalkUI
//
//  Created by hamed on 2/20/22.
//

import SwiftUI

public struct ListSectionButton: View {
    let imageName: String
    let title: String
    let color: Color
    let showDivider: Bool
    let shownavigationButton: Bool
    let action: (() -> ())?

    public init(imageName: String, title: String, color: Color, showDivider: Bool = true, shownavigationButton: Bool = true, action: (() -> Void)? = nil) {
        self.imageName = imageName
        self.title = title
        self.color = color
        self.showDivider = showDivider
        self.action = action
        self.shownavigationButton = shownavigationButton
    }

    public var body: some View {
        Button {
            action?()
        } label: {
            VStack(alignment: .leading) {
                HStack(spacing: 16) {
                    HStack {
                        Image(systemName: imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundColor(.white)
                    }
                    .frame(width: 28, height: 28)
                    .background(color)
                    .cornerRadius(8, corners: .allCorners)

                    Text(String(localized: .init(title)))
                    if shownavigationButton {
                        Spacer()
                        Image(systemName: "chevron.forward")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .foregroundStyle(.gray.opacity(0.8))
                    }
                }
                if showDivider {
                    Rectangle()
                        .fill(.gray.opacity(0.35))
                        .frame(height: 0.5)
                        .padding([.leading])
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 36, alignment: .leading)
            .contentShape(Rectangle())
            .padding(.top, 12)
            .padding([.leading, .trailing], 16)
            .padding(.bottom, showDivider ? 0 : 12)
        }
        .buttonStyle(ListSectionButtonStyle())
        .contentShape(Rectangle())
    }
}

struct ListSectionButtonStyle: ButtonStyle {

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.gray.opacity(0.3) : Color.clear)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct ListSectionButton_Previews: PreviewProvider {
    static var previews: some View {
        ListSectionButton(imageName: "TEST", title: "TIITLE", color: .red)
    }
}
