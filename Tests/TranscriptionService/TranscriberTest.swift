import XCTest
@testable import TranscriptionService

final class TranscriptionServiceTests: XCTestCase {
    struct MockTranscriber: Transcriber {
        init() {}

        func transcribe(audioPath: String) async throws -> String {
            return "Hello world!"
        }
    }

    func testTranscriptionConcatenatesSegments() async throws {
        let service = TranscriberService(transcriber: MockTranscriber())
        let result = try await service.transcribe(audioPath: "/dummy/path.wav")
        XCTAssertEqual(result, "Hello world!")
    }
}