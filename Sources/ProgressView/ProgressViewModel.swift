import Foundation
import Combine

public class ProgressViewModel: ObservableObject {
    @Published public var progress: Double = 0.0
    @Published public var text: String = "Initializing..."

    public init() {}

    public func updateProgress(to value: Double, with text: String) {
        DispatchQueue.main.async {
            self.progress = value
            self.text = text
        }
    }
}