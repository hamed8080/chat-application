//
//  DetailEditConversationButton.swift
//  Talk
//
//  Created by hamed on 5/6/24.
//

import SwiftUI
import TalkViewModels
//
//struct DetailEditConversationButton: View {
//    @EnvironmentObject var viewModel: ThreadDetailViewModel
//    @Environment(\.colorScheme) private var colorScheme
//
//    var body: some View {
//        if viewModel.canShowEditConversationButton == true {
//            NavigationLink {
//                if viewModel.canShowEditConversationButton, let viewModel = viewModel.editConversationViewModel {
//                    EditGroup()
//                        .environmentObject(viewModel.threadVM ?? .init(thread: .init()))
//                        .environmentObject(viewModel)
//                        .navigationBarBackButtonHidden(true)
//                }
//            } label: {
//                Image("ic_edit")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 16, height: 16)
//                    .padding(8)
//                    .foregroundStyle(colorScheme == .dark ? Color.App.accent : Color.App.white)
//                    .fontWeight(.heavy)
//            }
//        }
//    }
//}
//
//struct EditConversationButton_Previews: PreviewProvider {
//    static var previews: some View {
//        DetailEditConversationButton()
//    }
//}
