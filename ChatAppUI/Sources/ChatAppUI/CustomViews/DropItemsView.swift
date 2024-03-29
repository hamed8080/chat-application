//
//  DropItemsView.swift
//  ChatApplication
//
//  Created by hamed on 3/13/23.
//

import SwiftUI
import ChatAppViewModels
import ChatAppModels

public struct DropItemsView: View {
    @EnvironmentObject var viewModel: ThreadViewModel

    public init() {}
    
    public var body: some View {
        VStack {
            List(viewModel.dropItems) { item in
                DropRowView(item: item)
            }
            Spacer()
            SendTextViewWithButtons {
                viewModel.sendDropFiles(viewModel.dropItems)
                viewModel.sheetType = nil
            } onCancel: {
                viewModel.sheetType = nil
            }
        }
    }
}

public struct DropRowView: View {
    let item: DropItem

    public var body: some View {
        HStack {
            if let data = item.data, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: 32, height: 32)
            } else if let icon = item.iconName {
                Image(systemName: icon)
            }

            Text(item.name ?? "")
                .font(.iransansBody)
            Spacer()
            Text(item.fileSize)
                .font(.iransansCaption2)
                .foregroundColor(.gray)
        }
        .padding()
    }
}

struct DropItemsView_Previews: PreviewProvider {
    static var previews: some View {
        DropItemsView()
    }
}
