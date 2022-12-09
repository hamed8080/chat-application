//
//  LogView.swift
//  ChatApplication
//
//  Created by hamed on 6/27/22.
//

import SwiftUI

struct LogView: View {
    @StateObject var vm = LogViewModel()

    var body: some View {
        List(vm.filtered) {
            LogRow(log: $0)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
        }
        .searchable(text: $vm.searchText, placement: .navigationBarDrawer, prompt: "Search inside Logs...") {
            if vm.searchText.isEmpty == false, vm.filtered.count < 1 {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundColor(.gray.opacity(0.8))
                    Text("Nothind has found.")
                        .foregroundColor(.gray.opacity(0.8))
                }
            }
        }
        .animation(.easeInOut, value: vm.filtered)
        .listStyle(.plain)
        .toolbar {
            ToolbarItemGroup {
                Button {
                    vm.clearLogs()
                } label: {
                    Label {
                        Text("Delete")
                    } icon: {
                        Image(systemName: "trash")
                            .font(.body.bold())
                    }
                }
            }
        }
        .navigationTitle(Text("Logs"))
    }
}

struct LogView_Previews: PreviewProvider {
    static var previews: some View {
        LogView(vm: LogViewModel(isPreview: true))
    }
}
