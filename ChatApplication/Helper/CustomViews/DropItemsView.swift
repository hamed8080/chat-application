//
//  DropItemsView.swift
//  ChatApplication
//
//  Created by hamed on 3/13/23.
//

import SwiftUI

struct DropItemsView: View {
    @EnvironmentObject var viewModel: ThreadViewModel
    var body: some View {
        VStack {
            List(viewModel.dropItems) { item in
                DropRowView(item: item)
            }
            Spacer()
            SendFileView {
                viewModel.sendDropFiles(viewModel.dropItems)
                viewModel.sheetType = nil
            } onCancel: {
                viewModel.sheetType = nil
            }
        }
    }
}

struct DropRowView: View {
    let item: DropItem

    var body: some View {
        HStack {
            if let data = item.data, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: 32, height: 32)
            } else if let icon = item.iconName {
                Image(systemName: icon)
            }

            Text(item.name ?? "")
            Spacer()
            Text(item.fileSize)
                .font(.caption)
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
