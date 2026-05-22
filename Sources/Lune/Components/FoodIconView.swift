import SwiftUI

// Line-illustration food icons — faithfully ported from tokens.jsx FoodIcon component.
struct FoodIconView: View {
    let kind: String
    var size: CGFloat = 42
    var color: Color = .lTerracotta

    var body: some View {
        Group {
            switch kind {
            case "bowl":   BowlIcon(size: size, color: color)
            case "salmon": SalmonIcon(size: size, color: color)
            case "leaf":   LeafIcon(size: size, color: color)
            case "seed":   SeedIcon(size: size, color: color)
            case "cup":    CupIcon(size: size, color: color)
            case "fruit":  FruitIcon(size: size, color: color)
            default:
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.lCream2)
                    .frame(width: size, height: size)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Bowl
private struct BowlIcon: View {
    let size: CGFloat; let color: Color
    var body: some View {
        Canvas { ctx, s in
            let sc = s.width / 56
            // Bowl outline
            var bowl = Path()
            bowl.move(to: CGPoint(x: 8 * sc, y: 26 * sc))
            bowl.addLine(to: CGPoint(x: 48 * sc, y: 26 * sc))
            bowl.addQuadCurve(to: CGPoint(x: 28 * sc, y: 46 * sc),
                              control: CGPoint(x: 48 * sc, y: 50 * sc))
            bowl.addQuadCurve(to: CGPoint(x: 8 * sc, y: 26 * sc),
                              control: CGPoint(x: 8 * sc, y: 50 * sc))
            ctx.stroke(bowl, with: .color(color), lineWidth: 1.4 * sc)

            // Toppings
            ctx.fill(Path(ellipseIn: CGRect(x: 15 * sc, y: 19.5 * sc, width: 10 * sc, height: 5 * sc)),
                     with: .color(Color.lSage.opacity(0.8)))
            ctx.fill(Path(ellipseIn: CGRect(x: 28 * sc, y: 18 * sc, width: 8 * sc, height: 4 * sc)),
                     with: .color(Color.lTerracottaDeep.opacity(0.7)))
            ctx.fill(Path(ellipseIn: CGRect(x: 35 * sc, y: 22.4 * sc, width: 6 * sc, height: 3.2 * sc)),
                     with: .color(Color.lSage.opacity(0.6)))

            // Steam
            var steam = Path()
            steam.move(to: CGPoint(x: 28 * sc, y: 8 * sc))
            steam.addLine(to: CGPoint(x: 28 * sc, y: 14 * sc))
            ctx.stroke(steam, with: .color(color), lineWidth: 1.4 * sc,
                       style: StrokeStyle(lineCap: .round))

            var drop = Path()
            drop.move(to: CGPoint(x: 28 * sc, y: 9 * sc))
            drop.addCurve(to: CGPoint(x: 28 * sc, y: 12 * sc),
                          control1: CGPoint(x: 26 * sc, y: 9 * sc),
                          control2: CGPoint(x: 26 * sc, y: 12 * sc))
            drop.closeSubpath()
            ctx.fill(drop, with: .color(color.opacity(0.5)))
        }
    }
}

// MARK: - Salmon
private struct SalmonIcon: View {
    let size: CGFloat; let color: Color
    var body: some View {
        Canvas { ctx, s in
            let sc = s.width / 56
            // Upper body
            var upper = Path()
            upper.move(to: CGPoint(x: 8 * sc, y: 28 * sc))
            upper.addCurve(to: CGPoint(x: 48 * sc, y: 22 * sc),
                           control1: CGPoint(x: 16 * sc, y: 14 * sc),
                           control2: CGPoint(x: 36 * sc, y: 14 * sc))
            upper.addCurve(to: CGPoint(x: 8 * sc, y: 28 * sc),
                           control1: CGPoint(x: 44 * sc, y: 26 * sc),
                           control2: CGPoint(x: 18 * sc, y: 26 * sc))
            upper.closeSubpath()
            ctx.stroke(upper, with: .color(color), lineWidth: 1.4 * sc,
                       style: StrokeStyle(lineJoin: .round))

            // Lower body
            var lower = Path()
            lower.move(to: CGPoint(x: 8 * sc, y: 28 * sc))
            lower.addCurve(to: CGPoint(x: 48 * sc, y: 36 * sc),
                           control1: CGPoint(x: 16 * sc, y: 42 * sc),
                           control2: CGPoint(x: 36 * sc, y: 42 * sc))
            ctx.stroke(lower, with: .color(color), lineWidth: 1.4 * sc,
                       style: StrokeStyle(lineJoin: .round))

            // Tail fins
            let fins: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
                (48, 22, 43, 19), (48, 30, 43, 33)
            ]
            for (x1, y1, x2, y2) in fins {
                var fin = Path()
                fin.move(to: CGPoint(x: x1 * sc, y: y1 * sc))
                fin.addLine(to: CGPoint(x: x2 * sc, y: y2 * sc))
                ctx.stroke(fin, with: .color(color), lineWidth: 1.4 * sc,
                           style: StrokeStyle(lineCap: .round))
            }

            // Eye
            ctx.fill(Path(ellipseIn: CGRect(x: 16.5 * sc, y: 24.5 * sc, width: 3 * sc, height: 3 * sc)),
                     with: .color(color))

            // Scale lines
            let scales: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
                (14, 22, 16, 26), (22, 22, 20, 26), (28, 22, 29, 26), (34, 22, 33, 26)
            ]
            for (x1, y1, x2, y2) in scales {
                var l = Path()
                l.move(to: CGPoint(x: x1 * sc, y: y1 * sc))
                l.addLine(to: CGPoint(x: x2 * sc, y: y2 * sc))
                ctx.stroke(l, with: .color(color.opacity(0.5)), lineWidth: 0.8 * sc,
                           style: StrokeStyle(lineCap: .round))
            }
        }
    }
}

// MARK: - Leaf
private struct LeafIcon: View {
    let size: CGFloat; let color: Color
    var body: some View {
        Canvas { ctx, s in
            let sc = s.width / 56
            var leaf = Path()
            leaf.move(to: CGPoint(x: 14 * sc, y: 42 * sc))
            leaf.addCurve(to: CGPoint(x: 42 * sc, y: 14 * sc),
                          control1: CGPoint(x: 14 * sc, y: 26 * sc),
                          control2: CGPoint(x: 26 * sc, y: 14 * sc))
            leaf.addCurve(to: CGPoint(x: 14 * sc, y: 42 * sc),
                          control1: CGPoint(x: 42 * sc, y: 26 * sc),
                          control2: CGPoint(x: 26 * sc, y: 42 * sc))
            leaf.closeSubpath()
            ctx.stroke(leaf, with: .color(color), lineWidth: 1.4 * sc,
                       style: StrokeStyle(lineJoin: .round))

            var spine = Path()
            spine.move(to: CGPoint(x: 14 * sc, y: 42 * sc))
            spine.addLine(to: CGPoint(x: 42 * sc, y: 14 * sc))
            ctx.stroke(spine, with: .color(color), lineWidth: 1.4 * sc,
                       style: StrokeStyle(lineCap: .round))

            let veins: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
                (20, 36, 28, 28), (26, 30, 32, 24), (32, 24, 36, 20)
            ]
            for (x1, y1, x2, y2) in veins {
                var v = Path()
                v.move(to: CGPoint(x: x1 * sc, y: y1 * sc))
                v.addLine(to: CGPoint(x: x2 * sc, y: y2 * sc))
                ctx.stroke(v, with: .color(color.opacity(0.6)), lineWidth: 0.9 * sc,
                           style: StrokeStyle(lineCap: .round))
            }
        }
    }
}

// MARK: - Seed
private struct SeedIcon: View {
    let size: CGFloat; let color: Color
    var body: some View {
        Canvas { ctx, s in
            let sc = s.width / 56
            let seeds: [(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat)] = [
                (20, 32, 6, 4, -20), (36, 26, 6, 4, 25),
                (28, 40, 6, 4, 5),   (30, 16, 5, 3.5, 40),
            ]
            for (cx, cy, rx, ry, deg) in seeds {
                let angle = deg * Double.pi / 180
                let ellipseRect = CGRect(
                    x: (cx - rx) * sc, y: (cy - ry) * sc,
                    width: rx * 2 * sc, height: ry * 2 * sc
                )
                var e = Path(ellipseIn: ellipseRect)
                var t = CGAffineTransform(translationX: cx * sc, y: cy * sc)
                    .rotated(by: angle)
                    .translatedBy(x: -cx * sc, y: -cy * sc)
                e = e.applying(t)
                ctx.stroke(e, with: .color(color), lineWidth: 1.4 * sc)
            }
        }
    }
}

// MARK: - Cup
private struct CupIcon: View {
    let size: CGFloat; let color: Color
    var body: some View {
        Canvas { ctx, s in
            let sc = s.width / 56
            var cup = Path()
            cup.move(to: CGPoint(x: 14 * sc, y: 18 * sc))
            cup.addLine(to: CGPoint(x: 38 * sc, y: 18 * sc))
            cup.addLine(to: CGPoint(x: 38 * sc, y: 36 * sc))
            cup.addQuadCurve(to: CGPoint(x: 14 * sc, y: 36 * sc),
                             control: CGPoint(x: 26 * sc, y: 44 * sc))
            cup.closeSubpath()
            ctx.stroke(cup, with: .color(color), lineWidth: 1.4 * sc,
                       style: StrokeStyle(lineJoin: .round))

            var handle = Path()
            handle.move(to: CGPoint(x: 38 * sc, y: 22 * sc))
            handle.addLine(to: CGPoint(x: 42 * sc, y: 22 * sc))
            handle.addArc(center: CGPoint(x: 42 * sc, y: 26 * sc),
                          radius: 4 * sc,
                          startAngle: .degrees(-90),
                          endAngle: .degrees(90),
                          clockwise: false)
            handle.addLine(to: CGPoint(x: 38 * sc, y: 30 * sc))
            ctx.stroke(handle, with: .color(color), lineWidth: 1.4 * sc,
                       style: StrokeStyle(lineCap: .round))

            let steam: [(CGFloat, CGFloat)] = [(20, 10), (28, 10), (36, 10)]
            for (x, startY) in steam {
                var st = Path()
                st.move(to: CGPoint(x: x * sc, y: startY * sc))
                st.addCurve(to: CGPoint(x: x * sc, y: (startY + 4) * sc),
                            control1: CGPoint(x: (x - 2) * sc, y: (startY + 1) * sc),
                            control2: CGPoint(x: (x - 2) * sc, y: (startY + 3) * sc))
                st.addCurve(to: CGPoint(x: x * sc, y: (startY + 8) * sc),
                            control1: CGPoint(x: x * sc, y: (startY + 4) * sc),
                            control2: CGPoint(x: (x + 2) * sc, y: (startY + 6) * sc))
                ctx.stroke(st, with: .color(color.opacity(0.6)), lineWidth: 1.2 * sc,
                           style: StrokeStyle(lineCap: .round))
            }
        }
    }
}

// MARK: - Fruit
private struct FruitIcon: View {
    let size: CGFloat; let color: Color
    var body: some View {
        Canvas { ctx, s in
            let sc = s.width / 56
            // Main fruit circle
            ctx.stroke(Path(ellipseIn: CGRect(x: 14 * sc, y: 16 * sc, width: 28 * sc, height: 30 * sc)),
                       with: .color(color), lineWidth: 1.4 * sc)

            // Stem
            var stem = Path()
            stem.move(to: CGPoint(x: 28 * sc, y: 16 * sc))
            stem.addLine(to: CGPoint(x: 29 * sc, y: 9 * sc))
            ctx.stroke(stem, with: .color(Color.lSage), lineWidth: 1.4 * sc,
                       style: StrokeStyle(lineCap: .round))

            // Leaf on stem
            var leaf = Path()
            leaf.move(to: CGPoint(x: 29 * sc, y: 12 * sc))
            leaf.addCurve(to: CGPoint(x: 34 * sc, y: 9 * sc),
                          control1: CGPoint(x: 32 * sc, y: 10 * sc),
                          control2: CGPoint(x: 34 * sc, y: 9 * sc))
            ctx.stroke(leaf, with: .color(Color.lSage), lineWidth: 1.4 * sc,
                       style: StrokeStyle(lineCap: .round))
        }
    }
}
