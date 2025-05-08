import SwiftUI

struct StarOverlay: View {
    let starCount = 25

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<starCount, id: \.self) { _ in
                    StarSpriteView()
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .scaleEffect(Double.random(in: 0.5...1.2))
                        .opacity(Double.random(in: 0.4...0.8))
                }
            }
        }
        .ignoresSafeArea()
    }
}
