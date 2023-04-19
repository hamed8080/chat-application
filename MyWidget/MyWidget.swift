//
//  MyWidget.swift
//  MyWidget
//
//  Created by Hamed Hosseini on 11/21/21.
//

import AdditiveUI
import Chat
import ChatAppExtensions
import ChatAppModels
import ChatModels
import Intents
import SwiftUI
import WidgetKit

var previewThreads: [ThreadWithImageData] {
    var threads: [ThreadWithImageData] = []
    for i in 1 ... 12 {
        let imageURL = Bundle.main.url(forResource: "avatar\(i)", withExtension: "jpeg")
        threads.append(.init(thread: Conversation(id: i, title: "Ashly peterson"), imageURL: imageURL))
    }
    threads.append(.init(thread: Conversation(id: 12, title: "Ashly peterson"), imageURL: nil))
    return threads
}

struct Provider: IntentTimelineProvider {
    @AppStorage("Threads", store: UserDefaults.group) var threadsData: Data?

    func placeholder(in _: Context) -> SimpleEntry {
        SimpleEntry(threads: previewThreads)
    }

    func getSnapshot(for _: ConfigurationIntent, in _: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = SimpleEntry(threads: previewThreads)
        completion(entry)
    }

    func getTimeline(for _: ConfigurationIntent, in _: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        guard let threadsData = threadsData, let threads = try? JSONDecoder().decode([Conversation].self, from: threadsData)
        else {
            return
        }
        var entries: [SimpleEntry] = []
        var threadsWithImage: [ThreadWithImageData] = []
        let cache = CacheFileManager(group: AppGroup.group)
        threads.sorted(by: { $0.time ?? 0 > $1.time ?? 0 }).forEach { thread in
            let url = cache.filePathInGroup(url: URL(string: thread.image ?? "")!)
            threadsWithImage.append(.init(thread: thread, imageURL: url))
        }
        let entry = SimpleEntry(threads: threadsWithImage)
        entries.append(entry)
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct ThreadWithImageData: Identifiable {
    var id: Int { thread.id ?? 0 }
    let thread: Conversation
    var imageURL: URL?
}

struct SimpleEntry: TimelineEntry {
    var date: Date = .init()
    let threads: [ThreadWithImageData]
}

struct BlurNameWidgetView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    let mediumColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    let largColumns = [
        GridItem(.flexible(), spacing: 0),
        GridItem(.flexible(), spacing: 0),
        GridItem(.flexible(), spacing: 0),
    ]

    let extraLargColumns = [
        GridItem(.flexible(), spacing: 0),
        GridItem(.flexible(), spacing: 0),
        GridItem(.flexible(), spacing: 0),
        GridItem(.flexible(), spacing: 0),
    ]

    @ViewBuilder var body: some View {
        switch widgetFamily {
        case .systemExtraLarge:
            extraLargeView
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        case .systemLarge:
            largeView
        case .accessoryCircular:
            smallView
        case .accessoryRectangular:
            smallView
        case .accessoryInline:
            smallView
        @unknown default:
            mediumView
        }
    }

    @ViewBuilder var smallView: some View {
        if let thread = entry.threads.sorted(by: { $0.imageURL?.absoluteString.count ?? 0 > $1.imageURL?.absoluteString.count ?? 0 }).first {
            Link(destination: URL(string: "Widget://link-\(thread.thread.id ?? 0)")!) {
                ZStack {
                    if let imageURL = thread.imageURL, let cgImage = imageURL.imageScale(width: 128)?.image {
                        Image(cgImage: cgImage)
                            .resizable()
                            .scaledToFill()
                    }
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text(thread.thread.title ?? "")
                                .font(.caption2)
                                .lineLimit(1)
                                .padding(12)
                            Spacer()
                        }
                        .background(.ultraThinMaterial)
                    }
                    .padding(0)
                }
            }
        }
    }

    @ViewBuilder var mediumView: some View {
        LazyVGrid(columns: mediumColumns) {
            ForEach(entry.threads.prefix(3), id: \.id) { thread in
                Link(destination: URL(string: "Widget://link-\(thread.thread.id ?? 0)")!) {
                    item(thread: thread)
                }
            }
        }
    }

    @ViewBuilder var largeView: some View {
        LazyVGrid(columns: largColumns, alignment: .center, spacing: 0) {
            ForEach(entry.threads.prefix(9), id: \.id) { thread in
                Link(destination: URL(string: "Widget://link-\(thread.thread.id ?? 0)")!) {
                    item(thread: thread)
                }
            }
        }
    }

    @ViewBuilder var extraLargeView: some View {
        LazyVGrid(columns: extraLargColumns, spacing: 0) {
            ForEach(entry.threads.prefix(8), id: \.id) { thread in
                Link(destination: URL(string: "Widget://link-\(thread.thread.id ?? 0)")!) {
                    item(thread: thread)
                }
            }
        }
    }

    @ViewBuilder
    func item(thread: ThreadWithImageData) -> some View {
        Link(destination: URL(string: "Widget://link-\(thread.thread.id ?? 0)")!) {
            ZStack {
                if let imageURL = thread.imageURL, let cgImage = imageURL.imageScale(width: 128)?.image {
                    Image(cgImage: cgImage)
                        .resizable()
                        .scaledToFill()

                } else {
                    VStack {
                        ZStack {
                            Text(String(thread.thread.title?.first ?? " ").uppercased())
                                .font(.title2.weight(.bold))
                        }
                        .frame(width: 52, height: 52)
                        .background(.ultraThinMaterial)
                        .cornerRadius(26)
                    }
                    .frame(minHeight: 180)
                }
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(thread.thread.title ?? "")
                            .font(.caption2)
                            .lineLimit(1)
                            .padding(12)
                        Spacer()
                    }
                    .background(.ultraThinMaterial)
                }
                .padding(0)
            }
        }
    }
}

struct SimpleWidgetView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    let mediumColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    let largColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    let extraLargColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    @ViewBuilder var body: some View {
        switch widgetFamily {
        case .systemExtraLarge:
            extraLargeView
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        case .systemLarge:
            largeView
        case .accessoryCircular:
            smallView
        case .accessoryRectangular:
            smallView
        case .accessoryInline:
            smallView
        @unknown default:
            mediumView
        }
    }

    @ViewBuilder var smallView: some View {
        if let thread = entry.threads.sorted(by: { $0.imageURL?.absoluteString.count ?? 0 > $1.imageURL?.absoluteString.count ?? 0 }).first {
            Link(destination: URL(string: "Widget://link-\(thread.thread.id ?? 0)")!) {
                ZStack {
                    if let imageURL = thread.imageURL, let cgImage = imageURL.imageScale(width: 128)?.image {
                        Image(cgImage: cgImage)
                            .resizable()
                            .scaledToFill()
                    }
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text(thread.thread.title ?? "")
                                .font(.caption2)
                                .lineLimit(1)
                                .padding(12)
                            Spacer()
                        }
                        .background(.ultraThinMaterial)
                    }
                    .padding(0)
                }
            }
        }
    }

    @ViewBuilder var mediumView: some View {
        LazyVGrid(columns: mediumColumns) {
            ForEach(entry.threads.prefix(4), id: \.id) { thread in
                Link(destination: URL(string: "Widget://link-\(thread.thread.id ?? 0)")!) {
                    item(thread: thread)
                }
            }
        }
    }

    @ViewBuilder var largeView: some View {
        LazyVGrid(columns: largColumns, alignment: .center, spacing: 32) {
            ForEach(entry.threads.prefix(9), id: \.id) { thread in
                Link(destination: URL(string: "Widget://link-\(thread.thread.id ?? 0)")!) {
                    item(thread: thread)
                }
            }
        }
    }

    @ViewBuilder var extraLargeView: some View {
        LazyVGrid(columns: extraLargColumns, spacing: 36) {
            ForEach(entry.threads.prefix(12), id: \.id) { thread in
                Link(destination: URL(string: "Widget://link-\(thread.thread.id ?? 0)")!) {
                    item(thread: thread)
                }
            }
        }
    }

    @ViewBuilder
    func item(thread: ThreadWithImageData) -> some View {
        if let imageURL = thread.imageURL, let cgImage = imageURL.imageScale(width: 128)?.image {
            VStack(spacing: 4) {
                Image(uiImage: UIImage(cgImage: cgImage))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 52)
                    .background(.blue.opacity(0.5))
                    .cornerRadius(26)
                Text(thread.thread.title?.prefix(20) ?? "")
                    .font(.caption2.weight(.medium))
            }

        } else {
            VStack {
                ZStack {
                    Text(String(thread.thread.title?.first ?? " ").uppercased())
                        .font(.title2.weight(.bold))
                }
                .frame(width: 52, height: 52)
                .background(.ultraThinMaterial)
                .cornerRadius(26)
                Text(thread.thread.title?.prefix(20) ?? "")
                    .font(.caption2.weight(.medium))
            }
        }
    }
}

struct SimpleWidget: Widget {
    let kind: String = "SimpleWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            SimpleWidgetView(entry: entry)
        }
        .configurationDisplayName("Chat Widgets")
        .description("Choose widget to access quicker chats you like!")
    }
}

struct BlurNameWidget: Widget {
    let kind: String = "BlurNameWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            BlurNameWidgetView(entry: entry)
        }
        .configurationDisplayName("Chat Widgets")
        .description("Choose widget to access quicker chats you like!")
    }
}

@main
struct WidgetGroup: WidgetBundle {
    var body: some Widget {
        SimpleWidget()
        BlurNameWidget()
    }
}

struct MyWidget_Previews: PreviewProvider {
    static var previews: some View {
        SimpleWidgetView(entry: SimpleEntry(threads: previewThreads))
            .previewContext(WidgetPreviewContext(family: .systemExtraLarge))
            .previewDisplayName("Simple Widget")
        BlurNameWidgetView(entry: SimpleEntry(threads: previewThreads))
            .previewContext(WidgetPreviewContext(family: .systemExtraLarge))
            .previewDisplayName("Blur Widget")
    }
}
