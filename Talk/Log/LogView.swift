//
//  LogView.swift
//  Talk
//
//  Created by hamed on 6/27/22.
//

import Chat
import Logger
import SwiftUI
import TalkViewModels
import TalkUI

struct LogView: View {
    @EnvironmentObject var viewModel: LogViewModel

    var body: some View {
        List(viewModel.filtered) {
            LogRow(log: $0)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
        }
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer, prompt: "General.searchHere") {
            if viewModel.searchText.isEmpty == false, viewModel.filtered.count < 1 {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundColor(Color.App.gray1.opacity(0.8))
                    Text("General.nothingFound")
                        .foregroundColor(Color.App.gray1.opacity(0.8))
                }
            }
        }
        .navigationTitle("Logs.title")
        .animation(.easeInOut, value: viewModel.filtered.count)
        .listStyle(.plain)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItemGroup {
                trailingToolbars
            }

            ToolbarItemGroup(placement: .navigation) {
                NavigationBackButton {
                    AppState.shared.navViewModel?.remove(type: LogNavigationValue.self)
                }
            }
        }
    }

    @ViewBuilder var trailingToolbars: some View {
        Button {
            viewModel.deleteLogs()
        } label: {
            Label {
                Text("General.delete")
            } icon: {
                Image(systemName: "trash")
            }
        }

        Menu {
            Button {
                viewModel.type = nil
            } label: {
                if viewModel.type == nil {
                    Image(systemName: "checkmark")
                }
                Text("General.all")
            }
            ForEach(LogEmitter.allCases) { item in
                Button {
                    viewModel.type = item
                } label: {
                    if viewModel.type == item {
                        Image(systemName: "checkmark")
                    }
                    Text(.init(localized: .init(item.title)))
                }
            }
        } label: {
            Label("", systemImage: "line.3.horizontal.decrease.circle")
        }
    }
}

struct LogView_Previews: PreviewProvider {
    static var previews: some View {
        LogView()
            .environmentObject(LogViewModel())
    }
}
