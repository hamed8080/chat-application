//
//  MyWidget.swift
//  MyWidget
//
//  Created by Hamed Hosseini on 11/21/21.
//

import WidgetKit
import SwiftUI
import Intents
import FanapPodChatSDK

struct Provider: IntentTimelineProvider {
    
    @AppStorage("Threads", store: UserDefaults.group) var threadsData:Data?
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(threads: [], configuration: ConfigurationIntent())
    }
    
    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        
        guard let threadsData = threadsData, let threads = try? JSONDecoder().decode([Conversation].self, from: threadsData)
        else{
            return
        }
        let entry = SimpleEntry(threads: threads, configuration: configuration)
        completion(entry)
    }
    
    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        
        guard let threadsData = threadsData,let threads = try? JSONDecoder().decode([Conversation].self, from: threadsData)
        else{
            return
        }
        var entries: [SimpleEntry] = []
        let entry = SimpleEntry(threads: threads, configuration: configuration)
        entries.append(entry)
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    var date: Date = Date()
    let threads: [Conversation]
    let configuration: ConfigurationIntent
}

struct MyWidgetEntryView : View {
    
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
    
    @ViewBuilder
    var body: some View {
        switch widgetFamily{
        case .systemExtraLarge:
            extraLargeView
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        case .systemLarge:
            largeView
        @unknown default:
            mediumView
        }
    }
    
    @ViewBuilder
    var smallView: some View{
        if let thread = entry.threads.first{
            VStack{
                Avatar(url: thread.image, userName: thread.title?.uppercased(),fileMetaData: thread.metadata, imageSize: .SMALL)
                Text(thread.title ?? "")
                    .font(.subheadline)
            }.widgetURL(URL(string: "Widget://link-\(thread.id ?? 0 )")!)
        }
    }
    
    @ViewBuilder
    var mediumView: some View{
        let threads = getThreads(count: 8)
        LazyVGrid(columns: mediumColumns){
            ForEach(threads, id:\.id){ thread in
                item(thread: thread)
            }
        }
    }
    
    @ViewBuilder
    var largeView: some View{
        let threads = getThreads(count: 12)
        LazyVGrid(columns: largColumns, alignment: .center, spacing: 16){
            ForEach(threads, id:\.id){ thread in
                item(thread: thread)
            }
        }
    }
    
    @ViewBuilder
    var extraLargeView: some View{
        let threads = getThreads(count: 12)
        LazyVGrid(columns: largColumns){
            ForEach(threads, id:\.id){ thread in
                item(thread: thread)
            }
        }
    }
    
    func getThreads(count:Int)->[Conversation]{
        if entry.threads.count >= count{
            return Array(entry.threads[0...(count - 1)])
        }else{
            return entry.threads
        }
    }
    
    @ViewBuilder
    func item(thread:Conversation)-> some View{
        Link(destination: URL(string: "Widget://link-\(thread.id ?? 0 )")!) {
            Avatar(url: thread.image, userName: thread.title?.uppercased(),fileMetaData: thread.metadata, imageSize: .MEDIUM)
        }
    }
}

@main
struct MyWidget: Widget {
    let kind: String = "MyWidget"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            MyWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Chat Widgets")
        .description("Choose widget to access quicker chats you like!")
    }
}

struct MyWidget_Previews: PreviewProvider {
    static var previews: some View {
        MyWidgetEntryView(entry: SimpleEntry(threads: [], configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
