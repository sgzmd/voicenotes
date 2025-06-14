import Foundation
import TranscriptionService
import WhisperKit

public class WhisperKitTinyTranscriber: Transcriber {
    public init() {}

    public func transcribe(audioPath: String) async throws -> String {
        let config = WhisperKitConfig(model: "tiny")
        let modelPath = Bundle.module.path(
            forResource: "tiny", ofType: nil, inDirectory: "TestModels")!
        config.verbose = true

        let whisper = try await WhisperKit(config)
        let result = try await whisper.transcribe(audioPath: audioPath)
        let lines = result.flatMap { $0.segments }.map {
            $0.text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // TODO(sgzmd): There must be better way to handle this.
        let fullText =
            lines
            .map { $0.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression) }
            .joined(separator: "\n")

        return fullText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}
