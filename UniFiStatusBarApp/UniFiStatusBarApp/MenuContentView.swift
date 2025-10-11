import SwiftUI

struct MenuContentView: View {
    @EnvironmentObject var viewModel: UniFiViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let status = viewModel.controllerStatus {
                VStack(alignment: .leading, spacing: 4) {
                    Text("🔐 \(status.model ?? "Controller")")
                        .font(.headline)
                    Text("Status: \(status.version ?? "—")")
                    Text("IP: \(status.ip ?? "—")")

                    if let info = status.additionalInfo {
                        Divider()
                        ScrollView {
                            Text(info)
                                .font(.system(size: 11, weight: .regular, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                        }
                        .frame(height: 160)
                    }
                }
            } else if let error = viewModel.errorMessage {
                Text("\(error)").foregroundColor(.red)
            } else {
                Text("⏳ Loading...")
                    .onAppear { Task { await viewModel.refresh() } }
            }

            Divider().padding(.vertical, 8)
            HStack {
                Button("Enter UniFI API Key") {
                    NotificationCenter.default.post(name: .openSettings, object: nil)
                }
                Button("Quit", role: .destructive) {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding(12)
        .frame(width: 320)
    }
}
