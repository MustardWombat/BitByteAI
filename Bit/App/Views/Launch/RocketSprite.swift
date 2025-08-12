import SwiftUI
#if os(iOS)
import UIKit
#else
import AppKit
typealias UIImage = NSImage
#endif

public struct RocketSprite: View {
    @Binding var animate: Bool
    @Binding var isStudying: Bool

    private let spriteSize: CGFloat = 24
    private let scale: CGFloat = 8.0
    private let sheetName: String = "spaceship-Sheet"

    private enum AnimationState {
        case idle
        case launch
        case studying
    }
    
    private var animationState: AnimationState {
        if isAnimating {
            return .launch
        } else if isStudying {
            return .studying
        } else {
            return .idle
        }
    }
    
    // Animation parameters for each state
    private var totalFrames: Int {
        switch animationState {
        case .launch:
            return 6
        case .studying:
            return 3
        case .idle:
            return 1
        }
    }
    
    private var frameDuration: TimeInterval {
        switch animationState {
        case .launch:
            return 0.14
        case .studying:
            return 0.14
        case .idle:
            return 0
        }
    }
    
    private var rowY: CGFloat {
        switch animationState {
        case .launch:
            return 0
        case .studying:
            return 24
        case .idle:
            return 48
        }
    }
    
    @State private var spriteSheet: CGImage? = nil
    @State private var currentFrame: Int = 0
    @State private var isAnimating: Bool = false
    @State private var timer: Timer? = nil

    private var croppingRect: CGRect {
        switch animationState {
        case .launch, .studying:
            return CGRect(x: CGFloat(currentFrame) * spriteSize, y: rowY, width: spriteSize, height: spriteSize)
        case .idle:
            return CGRect(x: 168, y: 48, width: spriteSize, height: spriteSize)
        }
    }
    
    public init(animate: Binding<Bool>, isStudying: Binding<Bool>) {
        _animate = animate
        _isStudying = isStudying
    }
    
    public var body: some View {
        ZStack {
            if let spriteSheet = spriteSheet,
               let frame = spriteSheet.cropping(to: croppingRect) {
                Image(decorative: frame, scale: 1.0, orientation: .up)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: spriteSize * scale, height: spriteSize * scale)
            } else {
                Color.clear.frame(width: spriteSize * scale, height: spriteSize * scale)
            }
        }
        .onAppear {
            #if os(iOS)
            if let uiImage = UIImage(named: sheetName)?.cgImage {
                spriteSheet = uiImage
            }
            #else
            if let nsImage = NSImage(named: sheetName) {
                let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
                spriteSheet = cgImage
            }
            #endif
            currentFrame = 0
        }
        .onChange(of: animate) { newValue in
            if newValue && !isAnimating {
                startLaunchAnimation()
            }
        }
        .onChange(of: isStudying) { newValue in
            if newValue {
                currentFrame = 0
                startStudyingAnimation()
            } else {
                invalidateTimer()
                currentFrame = 0
            }
        }
        .frame(width: spriteSize * scale, height: spriteSize * scale)
    }
    
    private func startLaunchAnimation() {
        isAnimating = true
        currentFrame = 0
        invalidateTimer()
        timer = Timer.scheduledTimer(withTimeInterval: frameDuration, repeats: true) { _ in
            if currentFrame < totalFrames - 1 {
                currentFrame += 1
            } else {
                invalidateTimer()
                isAnimating = false
                animate = false
            }
        }
    }
    
    private func startStudyingAnimation() {
        isAnimating = false
        currentFrame = 0
        invalidateTimer()
        timer = Timer.scheduledTimer(withTimeInterval: frameDuration, repeats: true) { _ in
            currentFrame = (currentFrame + 1) % totalFrames
        }
    }
    
    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }
}
