//
//  NothingHasBeenSelectedView.swift
//  Talk
//
//  Created by hamed on 9/14/23.
//

import SwiftUI
import TalkViewModels
import TalkUI

struct NothingHasBeenSelectedView: View {
    let contactsVM: ContactsViewModel

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
                        .foregroundColor(Color.App.hint)
                        .multilineTextAlignment(.center)
                        .frame(minWidth: 220)
                    Button {
                        contactsVM.showConversaitonBuilder.toggle()
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "plus")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                            Text("General.createAConversation")
                        }
                    }
                    .fixedSize()
                    .font(.iransansBoldBody)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.App.bgSecond)
                    .cornerRadius(12)
                    .foregroundStyle(Color.App.text)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .inset(by: 0.5)
                            .stroke(Color.App.gray8, lineWidth: 1)
                    )
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .padding([.leading, .trailing], 96)
            .padding([.bottom, .top], 96)
            .background(MixMaterialBackground().ignoresSafeArea())
        }
    }
}

struct NothingHasBeenSelectedView_Previews: PreviewProvider {
    static var previews: some View {
        NothingHasBeenSelectedView(contactsVM: .init())
    }
}
