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
        if viewModel.isMapType, let fileLink = viewModel.fileMetaData?.file?.link, let downloadVM = viewModel.downloadFileVM {
            ZStack {
                /// We use max to at least have a width, because there are times that maxWidth is nil.
                let width = max(128, (ThreadViewModel.maxAllowedWidth)) - (18 + MessageRowBackground.tailSize.width)
                /// We use max to at least have a width, because there are times that maxWidth is nil.
                /// We use min to prevent the image gets bigger than 320 if it's bigger.
                let height = min(320, max(128, (ThreadViewModel.maxAllowedWidth)))
                MapImageDownloader(width: width, height: width)
                    .id(fileLink)
                    .environmentObject(downloadVM)
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius:(8)))
            }
            .padding(.top, viewModel.paddings.mapViewSapcingTop) /// We don't use spacing in the Main row in VStack because we don't want to have extra spcace.
            .onTapGesture {
                if let url = message.neshanURL, UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            }
            .task {
                if downloadVM.isInCache {
                    downloadVM.state = .completed
                    viewModel.animateObjectWillChange()
                } else {
                    downloadVM.startDownload()
                }
            }
        }
    }
}

struct MapImageDownloader: View {
    let width: CGFloat
    let height: CGFloat
    @State private var image = UIImage(named: "empty_image")!
    @EnvironmentObject var viewModel: DownloadFileViewModel

    var body: some View {
        if viewModel.fileURL != nil {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height)
                .clipped()
                .zIndex(0)
                .background(LinearGradient(colors: [Color.App.bgInput, Color.App.bgInput], startPoint: .top, endPoint: .bottom))
                .clipShape(RoundedRectangle(cornerRadius:(8)))
                .task {
                    if let scaledImage = viewModel.fileURL?.imageScale(width: Int(800))?.image {
                        image = UIImage(cgImage: scaledImage)
                    }
                }
        }
    }
}

struct LocationRowView_Previews: PreviewProvider {
    static var previews: some View {
        LocationRowView()
    }
}
