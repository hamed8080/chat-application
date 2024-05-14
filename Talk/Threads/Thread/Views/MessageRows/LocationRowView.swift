//
//  LocationRowView.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkViewModels
import Chat

struct LocationRowView: View {
    @EnvironmentObject var viewModel: MessageRowViewModel
    
    var body: some View {        
        ZStack {
            imageView
        }
        .padding(.top, viewModel.calMessage.sizes.paddings.mapViewSapcingTop) /// We don't use spacing in the Main row in VStack because we don't want to have extra spcace.
        .onTapGesture {
            viewModel.onTap()
        }
        .task {
            viewModel.downloadMap()
        }
    }

    private var imageView: some View {
        Image(uiImage: viewModel.fileState.image ?? DownloadFileManager.mapPlaceholder)
            .interpolation(.none)
            .resizable()
            .scaledToFill()
            .frame(width: viewModel.calMessage.sizes.mapWidth, height: viewModel.calMessage.sizes.mapHeight)
            .clipped()
            .zIndex(0)
            .opacity(viewModel.fileState.state == .completed ? 1.0 : 0.2)
            .background(LinearGradient(colors: [Color.App.bgInput, Color.App.bgInput], startPoint: .top, endPoint: .bottom))
            .clipShape(RoundedRectangle(cornerRadius:(8)))
            .animation(.easeInOut, value: viewModel.fileState.image)
            .clipShape(RoundedRectangle(cornerRadius:(8)))
    }
}

struct LocationRowView_Previews: PreviewProvider {
    static var previews: some View {
        LocationRowView()
    }
}
