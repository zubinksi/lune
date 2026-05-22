import SwiftUI

// MARK: - Moon lit region shape
// Faithfully ports the SVG path logic from moon.jsx.
// The lit region is constructed from:
//   1. A semicircle on the lit side (right=waxing, left=waning)
//   2. An elliptical terminator arc back to the start
struct MoonLitShape: Shape {
    var phase: Double   // 0..1

    func path(in rect: CGRect) -> Path {
        let r = min(rect.width, rect.height) * 0.48
        let cx = rect.midX
        let cy = rect.midY
        let top    = CGPoint(x: cx, y: cy - r)
        let bottom = CGPoint(x: cx, y: cy + r)

        var path = Path()

        if phase <= 0.005 { return path }   // new moon

        if phase >= 0.495 && phase <= 0.505 {
            // Full moon — entire disc
            path.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
            return path
        }

        let waxing  = phase < 0.5
        let litFrac = waxing ? phase * 2 : (1 - phase) * 2   // 0..1
        let rx      = r * (1 - 2 * litFrac)   // +r=thin crescent, -r=gibbous
        let absRx   = abs(rx)

        path.move(to: top)

        if waxing {
            // Right semicircle: top → clockwise → bottom
            path.addArc(center: CGPoint(x: cx, y: cy),
                        radius: r,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(90),
                        clockwise: false)   // counterclockwise in SwiftUI = right-side arc
            // Terminator ellipse: bottom → top
            if rx >= 0 {
                // Crescent: SVG sweep=0 → through left of ellipse
                addEllipseBottomToTop(&path, cx: cx, cy: cy, rx: absRx, ry: r, viaLeft: true)
            } else {
                // Gibbous: SVG sweep=1 → through right of ellipse
                addEllipseBottomToTop(&path, cx: cx, cy: cy, rx: absRx, ry: r, viaLeft: false)
            }
        } else {
            // Left semicircle: top → counterclockwise → bottom
            path.addArc(center: CGPoint(x: cx, y: cy),
                        radius: r,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(90),
                        clockwise: true)    // clockwise in SwiftUI = left-side arc
            // Terminator: 1-sweep relative to waxing
            if rx >= 0 {
                // Waning crescent: 1-0=1 → through right of ellipse
                addEllipseBottomToTop(&path, cx: cx, cy: cy, rx: absRx, ry: r, viaLeft: false)
            } else {
                // Waning gibbous: 1-1=0 → through left of ellipse
                addEllipseBottomToTop(&path, cx: cx, cy: cy, rx: absRx, ry: r, viaLeft: true)
            }
        }

        path.closeSubpath()
        return path
    }

    // Cubic-Bézier approximation of a half-ellipse: (cx, cy+ry) → (cx, cy-ry)
    // k = 0.5523 is the standard magic constant for quarter-circle Bézier arcs.
    private func addEllipseBottomToTop(_ path: inout Path,
                                       cx: CGFloat, cy: CGFloat,
                                       rx: CGFloat, ry: CGFloat,
                                       viaLeft: Bool) {
        let k: CGFloat = 0.5523
        if viaLeft {
            // bottom → left midpoint → top
            path.addCurve(
                to: CGPoint(x: cx - rx, y: cy),
                control1: CGPoint(x: cx - rx * k, y: cy + ry),
                control2: CGPoint(x: cx - rx, y: cy + ry * k)
            )
            path.addCurve(
                to: CGPoint(x: cx, y: cy - ry),
                control1: CGPoint(x: cx - rx, y: cy - ry * k),
                control2: CGPoint(x: cx - rx * k, y: cy - ry)
            )
        } else {
            // bottom → right midpoint → top
            path.addCurve(
                to: CGPoint(x: cx + rx, y: cy),
                control1: CGPoint(x: cx + rx * k, y: cy + ry),
                control2: CGPoint(x: cx + rx, y: cy + ry * k)
            )
            path.addCurve(
                to: CGPoint(x: cx, y: cy - ry),
                control1: CGPoint(x: cx + rx, y: cy - ry * k),
                control2: CGPoint(x: cx + rx * k, y: cy - ry)
            )
        }
    }
}

// MARK: - Moon View
struct MoonView: View {
    var phase: Double = 0.5
    var size: CGFloat = 200
    var litColor: Color = .lCream
    var darkColor: Color = .lInk
    var showCraters: Bool = true
    var showGlow: Bool = false

    var body: some View {
        ZStack {
            // Soft glow halo
            if showGlow {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [litColor.opacity(0), litColor.opacity(0.18)],
                            center: .center,
                            startRadius: size * 0.30,
                            endRadius: size * 0.50
                        )
                    )
                    .frame(width: size * 1.35, height: size * 1.35)
            }

            // Dark disc
            Circle()
                .fill(darkColor)
                .frame(width: size, height: size)

            // Lit region
            MoonLitShape(phase: phase)
                .fill(
                    RadialGradient(
                        colors: [litColor, litColor.opacity(0.92)],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.48
                    )
                )
                .frame(width: size, height: size)

            // Craters (subtle, on lit side only when phase has lit area)
            if showCraters && phase > 0.005 {
                CraterLayer(size: size, darkColor: darkColor)
                    .clipShape(MoonLitShape(phase: phase))
                    .frame(width: size, height: size)
            }

            // Subtle rim
            Circle()
                .strokeBorder(darkColor.opacity(0.18), lineWidth: size * 0.004)
                .frame(width: size, height: size)
        }
    }
}

struct CraterLayer: View {
    let size: CGFloat
    let darkColor: Color

    var body: some View {
        Canvas { ctx, s in
            let scale = s.width / 100
            let craters: [(CGFloat, CGFloat, CGFloat)] = [
                (38, 38, 3.5), (62, 44, 2.2), (55, 62, 4.0),
                (44, 68, 2.0), (68, 68, 2.6), (42, 52, 1.5),
            ]
            for (x, y, r) in craters {
                let rect = CGRect(
                    x: (x - r) * scale, y: (y - r) * scale,
                    width: r * 2 * scale, height: r * 2 * scale
                )
                ctx.fill(Path(ellipseIn: rect), with: .color(darkColor.opacity(0.18)))
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Mini moon icon for cycle strip
struct MoonIcon: View {
    var phase: Double = 0.5
    var size: CGFloat = 18
    var litColor: Color = .lInk
    var darkColor: Color = Color(red: 42/255, green: 37/255, blue: 32/255).opacity(0.12)

    var body: some View {
        MoonView(phase: phase, size: size, litColor: litColor, darkColor: darkColor,
                 showCraters: false, showGlow: false)
    }
}
