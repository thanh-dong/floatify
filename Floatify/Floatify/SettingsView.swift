import SwiftUI

struct SettingsView: View {
    @AppStorage("FloaterSize") private var floaterSize: String = "regular"

    var body: some View {
        Form {
            Section {
                Picker("Display Style", selection: $floaterSize) {
                    Text("Compact").tag("compact")
                    Text("Regular").tag("regular")
                    Text("Large").tag("large")
                }
                .pickerStyle(.inline)
            } header: {
                Text("Floater Appearance")
            } footer: {
                Text("Changes apply immediately to all visible floaters.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 320)
        .padding()
    }
}

#Preview {
    SettingsView()
}
