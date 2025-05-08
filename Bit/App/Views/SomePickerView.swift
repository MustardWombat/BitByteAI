import SwiftUI

struct PlatformSpecificPicker: View {
    @State private var selection: String = "Option1"
    let options: [String] = ["Option1", "Option2", "Option3"]

    var body: some View {
        Picker("Select Option", selection: $selection) {
            ForEach(options, id: \.self) { option in
                Text(option)
            }
        }
        #if os(iOS)
        .pickerStyle(WheelPickerStyle())
        #else
        .pickerStyle(DefaultPickerStyle())
        #endif
    }
}