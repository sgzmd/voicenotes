public protocol Transcriber {
    func transcribe(audioPath: String) async throws -> String
}

public class TranscriberService {
    public init(transcriber: any Transcriber) {
        self.transcriber = transcriber
    }

    private let transcriber: Transcriber
    public func transcribe(audioPath: String) async throws -> String {
        return try await transcriber.transcribe(audioPath: audioPath)
    }
}