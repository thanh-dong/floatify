import SwiftUI

struct SettingsView: View {
    @AppStorage("FloaterSize") private var floaterSize: String = "regular"
    @AppStorage("FloaterTheme") private var floaterTheme: String = "dark"
    @AppStorage("IdleTimeout") private var idleTimeout: Int = 15

    private let timeoutFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.allowsFloats = false
        f.minimum = 1
        f.maximum = 3600
        return f
    }()

    var body: some View {
        Form {
            Section {
                Picker("Theme", selection: $floaterTheme) {
                    Text("Dark").tag("dark")
                    Text("Light").tag("light")
                }
                .pickerStyle(.inline)

                Picker("Display Style", selection: $floaterSize) {
                    Text("Compact").tag("compact")
                    Text("Regular").tag("regular")
                    Text("Large").tag("large")
                    Text("Larger").tag("larger")
                    Text("Super Large").tag("superLarge")
                }
                .pickerStyle(.inline)
            } header: {
                Text("Floater Appearance")
            } footer: {
                Text("Changes apply immediately to all visible floaters.")
                    .foregroundStyle(.secondary)
            }

            Section {
                HStack {
                    Text("Idle timeout")
                    Spacer()
                    TextField("", value: $idleTimeout, formatter: timeoutFormatter)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("seconds")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Status Transitions")
            } footer: {
                Text("Delay before running transitions to idle, and idle to complete.")
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
