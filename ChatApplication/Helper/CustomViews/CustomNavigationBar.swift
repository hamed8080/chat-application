//
//  CustomNavigationBar.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 12/13/21.
//

import SwiftUI

struct CustomNavigationBar: View {
    var title: String?
    var subtitle: String?
    var showDivider: Bool = true
    var trailingActions: [NavigationItemButton] = []
    var leadingActions: [NavigationItemButton] = []
    var backButtonAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack {
                    if let backButtonAction = backButtonAction {
                        NavigationItemButton(systemImageName: "chevron.backward.circle.fill") {
                            backButtonAction()
                        }
                    }
                    ForEach(leadingActions, id: \.id) { item in
                        item
                    }
                    Spacer()
                    ForEach(trailingActions, id: \.id) { item in
                        item
                    }
                }

                HStack {
                    Spacer()
                    VStack {
                        if let title = title {
                            Text(title.uppercased())
                                .fontWeight(.medium)
                                .font(.headline)
                                .foregroundColor(Color(named: "text_color_blue").opacity(0.8))
                        }
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .fontWeight(.light)
                                .font(.subheadline)
                                .foregroundColor(Color(named: "text_color_blue").opacity(0.8))
                        }
                    }
                    Spacer()
                }
            }
            if showDivider == true {
                Rectangle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: .infinity, height: 0.5)
                    .padding(.top, 8)
            }
        }
        .padding(0)
    }
}

struct BackButton_Previews: PreviewProvider {
    static var previews: some View {
        CustomNavigationBar(title: "title", subtitle: "Connecting...",
                            trailingActions: [
                                .init(systemImageName: "pencil.circle.fill"),
                            ],
                            leadingActions: [
                                .init(systemImageName: "plus.circle.fill"),
                                .init(title: "Edit", systemImageName: "plus.circle.fill"),
                            ]) {}
    }
}

struct NavigationItemButton: View {
    let id: String? = UUID().string
    var title: String?
    var systemImageName: String?
    var foregroundColor: Color = .init(named: "text_color_blue").opacity(0.8)
    var font: Font = .title
    @State var visible: Bool = true
    @State var isEnabled: Bool = true

    var action: (() -> Void)?

    var body: some View {
        if visible {
            if let title = title {
                Text(title)
                    .foregroundColor(foregroundColor)
            } else {
                Button {
                    action?()
                } label: {
                    Image(systemName: systemImageName ?? "")
                        .font(font)
                }
                .buttonStyle(DeepButtonStyle(backgroundColor: .clear, shadow: 2))
                .foregroundColor(isEnabled ? foregroundColor : foregroundColor.opacity(0.5))
                .font(.largeTitle.weight(.light))
                .frame(width: 48, height: 48)
                .navigationBarTitle("", displayMode: .inline)
                .navigationBarHidden(true)
            }
        }
    }
}
