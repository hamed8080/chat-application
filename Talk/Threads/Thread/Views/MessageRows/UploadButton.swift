//
//  UploadButton.swift
//  Talk
//
//  Created by hamed on 2/5/24.
//

import SwiftUI
import TalkViewModels
import ChatModels

struct UploadButton: View {
    @EnvironmentObject var viewModel: MessageRowViewModel
    @Environment(\.colorScheme) var scheme

    var body: some View {
        Button {
            viewModel.cancelUpload()
        } label: {
            ZStack {
                iconView
                progress
            }
            .frame(width: 46, height: 46)
            .background(Color.App.accent)
            .clipShape(RoundedRectangle(cornerRadius:(46 / 2)))
        }
        .animation(.easeInOut, value: viewModel.fileState.progress)
        .animation(.easeInOut, value: viewModel.fileState.iconState)
        .buttonStyle(.borderless)
        .transition(.scale)
    }

    @ViewBuilder private var iconView: some View {
        Image(systemName: viewModel.fileState.iconState.replacingOccurrences(of: ".circle", with: ""))
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .frame(width: 16, height: 16)
            .foregroundStyle(Color.App.white)
            .fontWeight(.medium)
    }

    @ViewBuilder private var progress: some View {
        Circle()
            .trim(from: 0.0, to: viewModel.fileState.progress)
            .stroke(style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            .foregroundStyle(Color.App.white)
            .rotationEffect(Angle(degrees: 270))
            .frame(width: 42, height: 42)
            .environment(\.layoutDirection, .leftToRight)
            .fontWeight(.semibold)
            .rotateAnimtion(pause: !viewModel.fileState.isUploading)
    }
}

struct UploadButton_Previews: PreviewProvider {
    static var previews: some View {
        UploadButton()
    }
}
