import SwiftUI
import Combine

struct SpinningPlanetView: View {
    private let frameCount = 6
    private let frameSize: CGFloat = 24.0 // Each frame is 24x24 pixels
    private let frameDuration: Double = 0.3
    private let scale: CGFloat = 8.0

    @State private var currentFrame: Int = 0
    @State private var timer: AnyCancellable?
    @State private var spriteSheet: CGImage? = nil

    var body: some View {
        ZStack {
            if let spriteSheet = spriteSheet,
               let frame = spriteSheet.cropping(to: CGRect(x: CGFloat(currentFrame) * frameSize, y: 0, width: frameSize, height: frameSize)) {
                Image(decorative: frame, scale: 1.0, orientation: .up)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: frameSize * scale, height: frameSize * scale)
                    .position(x: 150, y: 150)
            }
        }
        .frame(width: 300, height: 300, alignment: .center)
        .onAppear {
            if spriteSheet == nil {
                if let uiImage = UIImage(named: "planet-Sheet")?.cgImage {
                    spriteSheet = uiImage
                }
            }
            timer = Timer.publish(every: frameDuration, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    currentFrame = (currentFrame + 1) % frameCount
                }
        }
        .onDisappear {
            timer?.cancel()
        }
    }
}
