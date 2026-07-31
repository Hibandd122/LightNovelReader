import Foundation

public enum TTSProviderType {
    case apple
    case openAI(apiKey: String)
    case azure(apiKey: String, region: String)
    case edge
}

@MainActor
public struct TTSFactory {
    public static func createProvider(type: TTSProviderType) -> TTSProvider {
        switch type {
        case .apple:
            return AppleAVSpeechProvider()
        case .openAI(let apiKey):
            return OpenAIProvider(apiKey: apiKey)
        case .azure(let apiKey, let region):
            return AzureProvider(apiKey: apiKey, region: region)
        case .edge:
            return EdgeProvider()
        }
    }
}