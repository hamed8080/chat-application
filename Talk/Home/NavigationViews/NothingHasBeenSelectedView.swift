//
//  NothingHasBeenSelectedView.swift
//  Talk
//
//  Created by hamed on 9/14/23.
//

import SwiftUI
import TalkViewModels

struct NothingHasBeenSelectedView: View {
    let threadsVM: ThreadsViewModel

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                Image("talk_first_page")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 320, height: 222)
                VStack(spacing: 16) {
                    Text("General.nothingSelectedConversation")
                        .font(.iransansSubheadline)
                        .foregroundColor(.secondaryLabel)
                        .multilineTextAlignment(.center)
                    Button {
                        threadsVM.sheetType = .startThread
                    } label: {
                        Text("General.start")
                            .font(.iransansBoldBody)
                    }
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .padding([.leading, .trailing], 96)
            .padding([.bottom, .top], 96)
            .background(.ultraThinMaterial)
        }
    }
}

struct NothingHasBeenSelectedView_Previews: PreviewProvider {
    static var previews: some View {
        NothingHasBeenSelectedView(threadsVM: .init())
    }
}
