import SwiftUI

public struct CustomProgressView: View {
    @Binding var progress: Double // Progress value (0 to 100)
    var text: String // Text to display above the progress bar

    public init(progress: Binding<Double>, text: String) {
        self._progress = progress
        self.text = text
    }

    public var body: some View {
        VStack {
            Text(text)
                .font(.headline)
                .padding(.bottom, 10)
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 20)
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue)
                    .frame(width: CGFloat(progress) * 2, height: 20) // Assuming 200px max width
            }
            .padding()
        }
        .padding()
        .frame(width: 300, height: 150)
    }
}

struct CustomProgressView_Previews: PreviewProvider {
    static var previews: some View {
        CustomProgressView(progress: .constant(50), text: "Downloading...")
    }
}