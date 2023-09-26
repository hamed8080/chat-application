//
//  TabButtonItem.swift
//  Talk
//
//  Created by hamed on 9/14/23.
//

import SwiftUI

struct TabButtonItem: View {
    var title: String
    var image: Image
    let contextMenu: (any View)?
    var isSelected: Bool
    var onClick: () -> Void

    var body: some View {
        VStack {
            image
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(isSelected ? .orange : .primary)

            Text(title)
                .font(.caption2)
                .foregroundColor(isSelected ? .orange : .gray)
        }
        .contentShape(Rectangle())
        .padding(4)
        .contextMenu {
            if let contextMenu {
                AnyView(contextMenu)
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut) {
                onClick()
            }
        }
    }
}

struct TabItem_Previews: PreviewProvider {
    static var previews: some View {
        TabButtonItem(title: "", image: Image(systemName: ""), contextMenu: nil, isSelected: false) {}
    }
}