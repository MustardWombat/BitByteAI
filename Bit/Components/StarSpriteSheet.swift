import SwiftUI
import Combine

struct StarSpriteView: View {
    // MARK: - Constants
    private let frameCount = 6                 // Number of frames in the sheet
    private let frameSize: CGFloat = 32        // Width/height of each frame
    private let frameDuration: Double = 0.5    // Increased seconds per frame for a slower animation
    private let startDelay: Double = Double.random(in: 0...2) // Random start delay

    // MARK: - State
    @State private var currentFrame: Int = 0
    @State private var isVisible = false
    @State private var timer: Cancellable?

    var body: some View {
        GeometryReader { geo in
            Image("StarSpriteSheet")
                .resizable()
                .interpolation(.none)
                // Size the full sprite sheet (6 frames in a row)
                .frame(width: frameSize * CGFloat(frameCount), height: frameSize)
                // Offset so that the current frame is visible.
                .offset(x: -CGFloat(currentFrame) * frameSize - 16)
                // Create a 32×32 window and clip the rest
                .frame(width: frameSize, height: frameSize)
                .clipped()
                // Center the sprite within its container
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                .opacity(isVisible ? 1 : 0)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + startDelay) {
                        isVisible = true
                        startAnimationTimer()
                    }
                }
                .onDisappear {
                    timer?.cancel()
                }
        }
        .frame(width: frameSize, height: frameSize)
    }

    // MARK: - Animation Timer
    private func startAnimationTimer() {
        timer = Timer.publish(every: frameDuration, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                currentFrame = (currentFrame + 1) % frameCount
            }
    }
}

struct StarFieldView: View {
    // Number of stars you want to display
    private let numberOfStars = 10
    
    // Store the random positions once generated.
    @State private var starPositions: [CGPoint] = []
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // For each star, use its corresponding random position.
                ForEach(0..<numberOfStars, id: \.self) { index in
                    StarSpriteView()
                        .position(
                            starPositions.count == numberOfStars
                            ? starPositions[index]
                            : CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                        )
                }
            }
            .onAppear {
                // Generate star positions only once when the view appears.
                if starPositions.isEmpty {
                    starPositions = (0..<numberOfStars).map { _ in
                        CGPoint(
                            x: CGFloat.random(in: 0...geo.size.width),
                            y: CGFloat.random(in: 0...geo.size.height)
                        )
                    }
                }
            }
        }
    }
}
