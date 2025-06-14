import AVFoundation
import Foundation
import WhisperKit

protocol AudioRecorderDelegate: AnyObject {
    func audioRecorderDidStartRecording()
    func audioRecorderDidStopRecording()
    func audioRecorderDidFinishTranscription(_ text: String, audioURL: URL)
    func audioRecorderDidFailWithError(_ error: Error)
}

class AudioRecorder: NSObject {
    weak var delegate: AudioRecorderDelegate?

    private var recorder: AVAudioRecorder?
    private var meteringTimer: Timer?
    private(set) var isRecording = false

    // MARK: - Recording Methods

    func startRecording() throws {
        guard !isRecording else { return }

        // Create directory for voice notes
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folder = docs.appendingPathComponent("VoiceNotes")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        // Generate unique filename
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileURL = folder.appendingPathComponent("voice-note-\(timestamp).m4a")

        // Configure audio settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        // Create and configure recorder
        recorder = try AVAudioRecorder(url: fileURL, settings: settings)
        recorder?.delegate = self
        recorder?.prepareToRecord()
        recorder?.isMeteringEnabled = true

        // Start recording
        guard recorder?.record() == true else {
            throw AudioRecorderError.failedToStartRecording
        }

        isRecording = true
        startMetering()
        delegate?.audioRecorderDidStartRecording()
    }

    func stopRecording() {
        guard isRecording else { return }

        recorder?.stop()
        isRecording = false
        stopMetering()
        delegate?.audioRecorderDidStopRecording()

        // Start transcription after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.transcribeRecording()
        }
    }

    // MARK: - Public Transcription Method

    // func transcribe(audioPath: String) async throws -> String {
    //     let whisper = try await WhisperKit(WhisperKitConfig(model: "tiny"))
    //     let result = try await whisper.transcribe(audioPath: audioPath)
    //     return result.flatMap { $0.segments }.map { $0.text }.joined()
    // }

    // MARK: - Private Methods

    private func startMetering() {
        meteringTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {
            [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.recorder?.updateMeters()
            }
        }
    }
    private func stopMetering() {
        meteringTimer?.invalidate()
        meteringTimer = nil
    }

    private func transcribeRecording() {
        guard let url = recorder?.url else { return }

        Task {
            do {
                // Use the new TranscriptionService
                let fullText = try await TranscriptionService.transcribe(audioPath: url.path())

                // Save transcription to text file
                let textFileURL = url.deletingPathExtension().appendingPathExtension("txt")
                try fullText.write(to: textFileURL, atomically: true, encoding: .utf8)

                let outputURL = url.deletingPathExtension().appendingPathExtension("txt")
                await MainActor.run {
                    delegate?.audioRecorderDidFinishTranscription(fullText, audioURL: outputURL)
                }
            } catch {
                await MainActor.run {
                    delegate?.audioRecorderDidFailWithError(error)
                }
            }
        }
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            delegate?.audioRecorderDidFailWithError(AudioRecorderError.recordingFailed)
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            delegate?.audioRecorderDidFailWithError(error)
        }
    }
}

// MARK: - Error Types

enum AudioRecorderError: Error {
    case failedToStartRecording
    case recordingFailed

    var localizedDescription: String {
        switch self {
        case .failedToStartRecording:
            return "Failed to start recording"
        case .recordingFailed:
            return "Recording failed"
        }
    }
}
