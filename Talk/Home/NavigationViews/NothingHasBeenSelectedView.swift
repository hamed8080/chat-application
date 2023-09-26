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
            Image("chat_bg")
                .renderingMode(.template)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .foregroundStyle(Color.mint.gradient.opacity(0.3))

            VStack(spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .opacity(0.2)
                VStack(spacing: 16) {
                    Text("General.nothingSelected")
                        .font(.iransansSubheadline)
                        .foregroundColor(.secondaryLabel)
                    Button {
                        threadsVM.sheetType = .startThread
                    } label: {
                        Text("General.start")
                            .font(.iransansBoldBody)
                    }
                }
            }
            .padding([.leading, .trailing], 96)
            .padding([.bottom, .top], 96)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
    }
}

struct NothingHasBeenSelectedView_Previews: PreviewProvider {
    static var previews: some View {
        NothingHasBeenSelectedView(threadsVM: .init())
    }
}
