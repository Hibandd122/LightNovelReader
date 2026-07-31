import ActivityKit
import WidgetKit
import SwiftUI

public struct TTSLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var currentSentence: String
        public var progress: Double
    }
    
    public var novelTitle: String
    public var chapterTitle: String
}

struct TTSLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TTSLiveActivityAttributes.self) { context in
            // Lock screen / Banner UI
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "headphones")
                        .foregroundColor(.blue)
                    Text(context.attributes.novelTitle)
                        .font(.headline)
                    Spacer()
                    Text(context.attributes.chapterTitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text(context.state.currentSentence)
                    .font(.body)
                    .lineLimit(2)
                    
                ProgressView(value: context.state.progress)
                    .tint(.blue)
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "headphones")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(String(format: "%.0f%%", context.state.progress * 100))
                        .font(.caption)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.novelTitle)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.currentSentence)
                        .font(.caption)
                        .lineLimit(2)
                }
            } compactLeading: {
                Image(systemName: "headphones")
                    .foregroundColor(.blue)
            } compactTrailing: {
                ProgressView(value: context.state.progress)
                    .progressViewStyle(.circular)
                    .tint(.blue)
            } minimal: {
                Image(systemName: "headphones")
                    .foregroundColor(.blue)
            }
        }
    }
}
