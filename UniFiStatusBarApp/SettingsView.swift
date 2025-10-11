import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: UniFiViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("UniFi Connection")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Controller Host")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("e.g. 192.168.1.1", text: $viewModel.controllerHost)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("API Key")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("Paste your UniFi API Key", text: $viewModel.apiKey)
                    .textFieldStyle(.roundedBorder)
            }

            HStack(spacing: 12) {
                Button("Save") {
                    Task {
                        viewModel.saveControllerHost()
                        viewModel.saveApiKey()
                        closeSettingsWindow()
                        await viewModel.refresh()
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Cancel") {
                    closeSettingsWindow()
                }
            }

            Spacer()

            Text("Find your API key in UniFi OS → System Settings → API Access.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .frame(width: 420, height: 240)
    }
}
