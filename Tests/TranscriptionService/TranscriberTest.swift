import XCTest
@testable import TranscriptionService

final class TranscriptionServiceTests: XCTestCase {
    struct MockTranscriber: Transcriber {
        init() {}

        func transcribe(audioPath: String) async throws -> String {
            return "Hello world!"
        }
    }

    func testTranscriptionFake() async throws {
        let service = TranscriberService(transcriber: MockTranscriber())
        let result = try await service.transcribe(audioPath: "/dummy/path.wav")
        XCTAssertEqual(result, "Hello world!")
    }

    func testTranscriptionWhisperKit() async throws {
        let t = WhisperKitTinyTranscriber()
        let service = TranscriberService(transcriber: t)
        let result = try await service.transcribe(audioPath: "Assets/test.m4a")
        XCTAssertEqual(result, "How to dismantle an atomic bomb?")
    }
    
}