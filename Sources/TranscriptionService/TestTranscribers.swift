import WhisperKit

public class FakeTranscriber: Transcriber {
    public init() {}

    public func transcribe(audioPath: String) async throws -> String {
        return "Fake transcription"
    }
}

public class WhisperKitTinyTranscriber: Transcriber {
    public init() {}

    public func transcribe(audioPath: String) async throws -> String {
        let whisper = try await WhisperKit(WhisperKitConfig(model: "tiny"))
        let result = try await whisper.transcribe(audioPath: audioPath)
        return result.flatMap { $0.segments }.map { $0.text }.joined()
    }
}