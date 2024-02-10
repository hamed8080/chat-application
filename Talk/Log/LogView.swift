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
    @State private var shareDownloadedFile = false
    @State private var logFileURL: URL?

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
                        .foregroundColor(Color.App.textSecondary.opacity(0.8))
                    Text("General.nothingFound")
                        .foregroundColor(Color.App.textSecondary.opacity(0.8))
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
                    AppState.shared.objectsContainer.navVM.remove(type: LogNavigationValue.self)
                }
            }
        }
        .sheet(isPresented: $shareDownloadedFile) {
            if let logFileURL {
                ActivityViewControllerWrapper(activityItems: [logFileURL], title: logFileURL.lastPathComponent)
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

        Button {
            Task {
                let name = Date().getDate()
                let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("\(name).txt")
                let url = tmp
                let logMessages = viewModel.logs.compactMap{ log in
                    var message = "==================================\n"
                    message += "Type: \(String(describing: log.type ?? .internalLog).uppercased())\n"
                    message += "Level: \(String(describing: log.level ?? .verbose).uppercased())\n"
                    message += "Prefix: \(log.prefix ?? "")\n"
                    message += "UserInfo: \(log.userInfo ?? [:])\n"
                    message += "DateTime: \(LogRow.formatter.string(from: log.time ?? .now))\n"
                    message += "\(log.message ?? "")\n"
                    message += "==================================\n"
                    return message
                }
                let string = logMessages.joined(separator: "\n")
                try? string.write(to: url, atomically: true, encoding: .utf8)
                await MainActor.run {
                    self.logFileURL = url
                    shareDownloadedFile.toggle()
                }
            }
        } label: {
            Label {
                Text("General.save")
            } icon: {
                Image(systemName: "square.and.arrow.up")
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
