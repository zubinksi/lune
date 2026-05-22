import SwiftUI

// Cubic-Bézier sine wave that fills from bottom to progress fraction of height.
// Matches the TideWave component in tokens.jsx.
struct TideWaveView: View {
    var progress: Double    // 0..1
    var color: Color = .lTerracotta
    var height: CGFloat = 36

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let fillY = h - CGFloat(progress) * h
            let amp: CGFloat = 4

            ZStack(alignment: .top) {
                // Background track
                Color.lCream

                // Wave fill
                Path { path in
                    path.move(to: CGPoint(x: 0, y: fillY))
                    // First sine wave: 0 → w/2
                    path.addCurve(
                        to: CGPoint(x: w * 0.5, y: fillY),
                        control1: CGPoint(x: w * 0.25, y: fillY - amp),
                        control2: CGPoint(x: w * 0.5,  y: fillY + amp)
                    )
                    // Second sine wave: w/2 → w
                    path.addCurve(
                        to: CGPoint(x: w, y: fillY),
                        control1: CGPoint(x: w * 0.75, y: fillY - amp),
                        control2: CGPoint(x: w,        y: fillY + amp)
                    )
                    path.addLine(to: CGPoint(x: w, y: h))
                    path.addLine(to: CGPoint(x: 0, y: h))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.55), color.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .animation(.easeOut(duration: 0.6), value: progress)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .frame(height: height)
    }
}
