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
import Chat
import TalkModels

struct LocationRowView: View {
    @EnvironmentObject var viewModel: MessageRowViewModel
    var message: Message { viewModel.message }
    
    var body: some View {        
        ZStack {
            if let downloadVM = viewModel.downloadFileVM {
                MapImageDownloader()
                    .environmentObject(downloadVM)
                    .clipShape(RoundedRectangle(cornerRadius:(8)))
            }
        }
        .padding(.top, viewModel.sizes.paddings.mapViewSapcingTop) /// We don't use spacing in the Main row in VStack because we don't want to have extra spcace.
        .onTapGesture {
            if let url = message.neshanURL, UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
        .task {
            /// Message.id equal to nil means that we are in upload mode we don't have id
            if let uploadMessage = message as? UploadFileWithLocationMessage, message.id == nil {
                ChatManager.activeInstance?.message.send(uploadMessage.locationRequest)
            } else {
                viewModel.downloadFileVM?.startDownload()
            }
        }
        .onReceive(viewModel.objectWillChange) { newValue in
            if (viewModel.message as? UploadFileWithLocationMessage) == nil {
                viewModel.downloadFileVM?.startDownload()
            }
        }
    }
}

struct MapImageDownloader: View {
    @State private var image = UIImage(named: "map_placeholder")!
    /// 0.2 Makes the map placeholder dimmer.
    @State private var opacity: CGFloat = 0.05
    @EnvironmentObject var viewModel: DownloadFileViewModel
    @EnvironmentObject var messageVM: MessageRowViewModel

    var body: some View {
        Image(uiImage: image)
            .interpolation(.none)
            .resizable()
            .scaledToFill()
            .frame(width: messageVM.sizes.mapWidth, height: messageVM.sizes.mapHeight)
            .clipped()
            .zIndex(0)
            .opacity(opacity)
            .background(LinearGradient(colors: [Color.App.bgInput, Color.App.bgInput], startPoint: .top, endPoint: .bottom))
            .clipShape(RoundedRectangle(cornerRadius:(8)))
            .animation(.easeInOut, value: image)
            .task {
                setImage()
                manageDownload()
            }
            .onReceive(viewModel.objectWillChange) { newValue in
                setImage()
            }
    }

    private func setImage() {
        if let scaledImage = viewModel.fileURL?.imageScale(width: Int(800))?.image, opacity != 1.0 {
            image = UIImage(cgImage: scaledImage)
            opacity = 1.0
        }
    }

    private func manageDownload() {
        if viewModel.isInCache {
            viewModel.state = .completed
            viewModel.animateObjectWillChange()
        }
    }
}

struct LocationRowView_Previews: PreviewProvider {
    static var previews: some View {
        LocationRowView()
    }
}
