import SwiftUI
import Combine

struct SettingsView: View {
    @EnvironmentObject var viewModel: UniFiViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🔐 Enter UniFi API Key")
                .font(.headline)

            TextField("Paste your API Key here", text: $viewModel.apiKey)
                .textFieldStyle(.roundedBorder)
                .padding(.bottom, 8)

            Button("💾 Save and Connect") {
                Task {
                    viewModel.saveApiKey()
                    closeSettingsWindow()
                    await viewModel.refresh()
                }
            }
            .buttonStyle(.borderedProminent)

            Spacer()

            Text("You can find your API key in UniFi OS → System Settings → API Access.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .frame(width: 360, height: 180)
    }
}
