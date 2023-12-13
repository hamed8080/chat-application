//
//  ContactListSearchBarFilterView.swift
//  Talk
//
//  Created by hamed on 12/13/23.
//

import SwiftUI
import TalkViewModels
import TalkModels

struct ContactListSearchBarFilterView: View {
    @Binding var isInSearchMode: Bool
    @State var text: String = ""
    @EnvironmentObject var viewModel: ContactsViewModel
    enum Field: Hashable {
        case saerch
    }
    @FocusState var searchFocus: Field?

    var body: some View {
        HStack {
            if isInSearchMode {
                TextField(String(localized: String.LocalizationValue("General.searchHere")), text: $text)
                    .font(.iransansBody)
                    .textFieldStyle(.clear)
                    .focused($searchFocus, equals: .saerch)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 38)
                    .clipped()
                    .transition(.asymmetric(insertion: .push(from: .top), removal: .move(edge: .top).combined(with: .opacity)))
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.clear)
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                Menu {
                    ForEach(SearchParticipantType.allCases.filter({ $0 != .admin })) { item in
                        Button {
                            withAnimation {
                                viewModel.searchType = item
                            }
                        } label: {
                            Text(String(localized: .init(item.rawValue)))
                                .font(.iransansBoldCaption3)
                        }
                    }
                } label: {
                    HStack {
                        Text(String(localized: .init(viewModel.searchType.rawValue)))
                            .font(.iransansBoldCaption3)
                            .foregroundColor(Color.App.hint)
                        Image(systemName: "chevron.down")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 8, height: 12)
                            .fontWeight(.medium)
                            .foregroundColor(Color.App.hint)
                    }
                }
            }
        }
        .animation(.easeInOut.speed(2), value: isInSearchMode)
        .padding(EdgeInsets(top: isInSearchMode ? 4 : 0, leading: 4, bottom: isInSearchMode ? 6 : 0, trailing: 4))
        .onChange(of: text) { newValue in
            viewModel.searchContactString = newValue
        }
        .onReceive(NotificationCenter.default.publisher(for: .forceSearch)) { newValue in
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                isInSearchMode.toggle()
                searchFocus = .saerch
            }
        }
    }
}

struct ContactListSearchBarFilterView_Previews: PreviewProvider {
    static var previews: some View {
        ContactListSearchBarFilterView(isInSearchMode: .constant(true))
    }
}
