//
//  LogView.swift
//  ChatApplication
//
//  Created by hamed on 6/27/22.
//

import FanapPodChatSDK
import SwiftUI

struct LogView: View {
    @EnvironmentObject var viewModel: LogViewModel

    var body: some View {
        List(viewModel.filtered) {
            LogRow(log: $0)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
        }
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer, prompt: "Search inside Logs...") {
            if viewModel.searchText.isEmpty == false, viewModel.filtered.count < 1 {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundColor(.gray.opacity(0.8))
                    Text("Nothind has found.")
                        .foregroundColor(.gray.opacity(0.8))
                }
            }
        }
        .navigationTitle("Logs")
        .animation(.easeInOut, value: viewModel.filtered.count)
        .listStyle(.plain)
        .toolbar {
            ToolbarItemGroup {
                trailingToolbars
            }
        }
    }

    @ViewBuilder var trailingToolbars: some View {
        Button {
            viewModel.deleteLogs()
        } label: {
            Label {
                Text("Delete")
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
                Text("All")
            }
            ForEach(LogEmitter.allCases) { item in
                Button {
                    viewModel.type = item
                } label: {
                    if viewModel.type == item {
                        Image(systemName: "checkmark")
                    }
                    Text(item.title)
                }
            }
        } label: {
            Label("Filter by", systemImage: "line.3.horizontal.decrease.circle")
        }
    }
}

struct LogView_Previews: PreviewProvider {
    static var previews: some View {
        LogView()
            .environmentObject(LogViewModel(isPreview: true))
    }
}
