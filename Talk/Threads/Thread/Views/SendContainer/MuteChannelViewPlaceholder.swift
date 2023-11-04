//
//  MuteChannelViewPlaceholder.swift
//  Talk
//
//  Created by hamed on 11/3/23.
//

import SwiftUI
import TalkViewModels
import TalkExtensions
import TalkUI
import Chat

struct MuteChannelViewPlaceholder: View {
    @EnvironmentObject var viewModel: ThreadViewModel
    @State var mute: Bool = false

    var body: some View {
        if viewModel.canShowMute {
            HStack(spacing: 0) {
                Spacer()
                Image(systemName: mute ? "speaker.fill" : "speaker.slash.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundColor(Color.App.primary)
                Text(mute ? "Thread.unmute" : "Thread.mute")
                    .font(.iransansSubheadline)
                    .offset(x: 8)
                    .foregroundStyle(Color.App.primary)
                Spacer()
            }
            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .bottom)))
            .onTapGesture {
                viewModel.threadsViewModel?.toggleMute(viewModel.thread)
            }
            .onReceive(NotificationCenter.default.publisher(for: .thread)) { newValue in
                if let event = newValue.object as? ThreadEventTypes {
                    if case let .mute(response) = event, response.subjectId == viewModel.threadId {
                        mute = true
                    }

                    if case let .unmute(response) = event, response.subjectId == viewModel.threadId {
                        mute = false
                    }
                }
            }
            .onAppear {
                mute = viewModel.thread.mute ?? false
            }
            .animation(.easeInOut, value: mute)
        }
    }
}

struct MuteChannelViewPlaceholder_Previews: PreviewProvider {
    static var previews: some View {
        MuteChannelViewPlaceholder()
    }
}
