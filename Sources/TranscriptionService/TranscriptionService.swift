
import Foundation
import WhisperKit

public class TranscriptionService {
    public static func transcribe(audioPath: String) async throws -> String {
        // Initialize WhisperKit. Adjust model and options as needed.
        // Using "tiny" model for faster processing, especially for tests.
        // For more accurate transcription, consider using "base" or other larger models.
        let whisper = try await WhisperKit(WhisperKitConfig(model: "tiny"))
        let result = try await whisper.transcribe(audioPath: audioPath)
        
        // Concatenate all segments to form the full transcription
        let fullText = result.flatMap { $0.segments }.map { $0.text }.joined()
        return fullText
    }
}
