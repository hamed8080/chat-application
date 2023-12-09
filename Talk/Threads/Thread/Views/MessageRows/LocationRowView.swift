//
//  LocationRowView.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkUI
import TalkViewModels
import ChatModels

struct LocationRowView: View {
    @EnvironmentObject var viewModel: MessageRowViewModel
    var message: Message { viewModel.message }
    
    var body: some View {
        let meta = message.fileMetaData
        if message.isMapType, let fileLink = meta?.file?.link, let downloadVM = viewModel.downloadFileVM {
            ZStack {
                /// We use max to at least have a width, because there are times that maxWidth is nil.
                let width = max(128, (MessageRowViewModel.maxAllowedWidth)) - (18 + MessageRowBackground.tailSize.width)
                /// We use max to at least have a width, because there are times that maxWidth is nil.
                /// We use min to prevent the image gets bigger than 320 if it's bigger.
                let height = min(320, max(128, (MessageRowViewModel.maxAllowedWidth)))
                MapImageDownloader()
                    .id(fileLink)
                    .environmentObject(downloadVM)
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius:(8)))
            }
            .onTapGesture {
                if let url = message.appleMapsURL, UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            }
            .task {
                downloadVM.startDownload()
            }
        }
    }
}

struct MapImageDownloader: View {
    @EnvironmentObject var viewModel: DownloadFileViewModel

    var body: some View {
        /// We use max to at least have a width, because there are times that maxWidth is nil.
        let width = max(128, (MessageRowViewModel.maxAllowedWidth)) - (18 + MessageRowBackground.tailSize.width)
        if viewModel.state == .completed, let image = viewModel.fileURL?.imageScale(width: Int(width))?.image {
            Image(uiImage: UIImage(cgImage: image))
                .resizable()
                .scaledToFill()
        }
    }
}

struct LocationRowView_Previews: PreviewProvider {
    static var previews: some View {
        LocationRowView()
    }
}
