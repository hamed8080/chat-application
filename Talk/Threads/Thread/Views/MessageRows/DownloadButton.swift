//
//  DownloadButton.swift
//  Talk
//
//  Created by hamed on 2/5/24.
//

import SwiftUI
import TalkViewModels
import TalkModels

struct DownloadButton: View {
    @EnvironmentObject var viewModel: MessageRowViewModel
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                iconView
                progress
            }
            .frame(width: 46, height: 46)
            .background(Color.App.accent)
            .clipShape(RoundedRectangle(cornerRadius:(23)))
        }
        .buttonStyle(.borderless)
    }

    @ViewBuilder private var iconView: some View {
        Image(systemName: viewModel.fileState.iconState)
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .frame(width: 16, height: 16)
            .foregroundStyle(Color.App.white)
            .fontWeight(.medium)
    }

    @ViewBuilder private var progress: some View {
        if viewModel.fileState.state == .downloading {
            Circle()
                .trim(from: 0.0, to: viewModel.fileState.progress)
                .stroke(style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .foregroundStyle(Color.App.white)
                .rotationEffect(Angle(degrees: 270))
                .frame(width: 42, height: 42)
                .environment(\.layoutDirection, .leftToRight)
                .fontWeight(.semibold)
                .rotateAnimtion(pause: viewModel.fileState.state == .paused)
        }
    }
}

struct DownloadButton_Previews: PreviewProvider {
    static var previews: some View {
        DownloadButton {
            
        }
    }
}
