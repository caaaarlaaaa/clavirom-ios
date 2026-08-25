import SwiftUI

/// The container app exists only to host the keyboard extension and tell the
/// user how to turn it on. All the real work happens in the Keyboard target.
struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Clavatura rumantscha — Vallader") {
                    Text("This app adds a Romansh (Vallader) keyboard to your iPhone.")
                        .font(.body)
                }
                Section("Activar la clavatura") {
                    step(1, "Open Settings › General › Keyboard › Keyboards")
                    step(2, "Tap “Add New Keyboard…”")
                    step(3, "Choose ClaviRom — Vallader")
                    step(4, "Switch to it with the 🌐 globe key in any text field")
                }
                Section("Privacy") {
                    Text("This keyboard does not request Full Access and works fully offline.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("ClaviRom")
        }
    }

    private func step(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(n)")
                .font(.headline.monospacedDigit())
                .frame(width: 24, height: 24)
                .background(Circle().fill(.tint.opacity(0.15)))
            Text(text)
        }
    }
}

#Preview {
    ContentView()
}
