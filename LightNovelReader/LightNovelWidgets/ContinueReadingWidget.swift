import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), novelTitle: "Placeholder Novel", progress: 0.5)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), novelTitle: "Sample Novel", progress: 0.75)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // Fetch recent novel from AppGroup UserDefaults or SwiftData
        let entry = SimpleEntry(date: Date(), novelTitle: "Current Reading Novel", progress: 0.8)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let novelTitle: String
    let progress: Double
}

struct ContinueReadingWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Continue Reading")
                .font(.caption)
                .foregroundColor(.secondary)
                
            Text(entry.novelTitle)
                .font(.headline)
                .lineLimit(2)
                
            Spacer()
            
            ProgressView(value: entry.progress)
                .tint(.accentColor)
        }
        .padding()
        // URL for universal link / deep link to open ReaderView
        .widgetURL(URL(string: "lightnovelreader://open?novelId=123")) 
    }
}

struct ContinueReadingWidget: Widget {
    let kind: String = "ContinueReadingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ContinueReadingWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Continue Reading")
        .description("Jump back into your recent light novel.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
