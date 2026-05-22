import SwiftUI

// MARK: - Eyebrow
struct Eyebrow: View {
    let text: String
    var color: Color = .lInk3

    init(_ text: String, color: Color = .lInk3) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text.uppercased())
            .font(LFont.mono(10.5, weight: .medium))
            .tracking(1.5)
            .foregroundColor(color)
    }
}

// MARK: - Display headline
struct DisplayText: View {
    var size: CGFloat = 38
    var italic: Bool = false
    var alignment: TextAlignment = .leading
    let content: () -> Text

    var body: some View {
        content()
            .font(LFont.display(size, italic: italic))
            .tracking(-0.4)
            .lineSpacing(size * 0.05)
            .multilineTextAlignment(alignment)
            .foregroundColor(.lInk)
    }
}

// Convenience for plain string displays
struct DisplayLabel: View {
    let text: String
    var size: CGFloat = 38
    var italic: Bool = false
    var color: Color = .lInk

    var body: some View {
        Text(text)
            .font(LFont.display(size, italic: italic))
            .tracking(-0.4)
            .foregroundColor(color)
    }
}

// MARK: - Body
struct BodyText: View {
    let text: String
    var size: CGFloat = 15
    var color: Color = .lInk2
    var alignment: TextAlignment = .leading

    var body: some View {
        Text(text)
            .font(LFont.body(size))
            .tracking(-0.1)
            .lineSpacing(size * 0.55 * 0.4)
            .multilineTextAlignment(alignment)
            .foregroundColor(color)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Primary pill button
struct PillButton: View {
    let label: String
    var variant: PillVariant = .primary
    var disabled: Bool = false
    let action: () -> Void

    enum PillVariant { case primary, secondary, ghost }

    var body: some View {
        Button(action: { if !disabled { action() } }) {
            Text(label)
                .font(LFont.body(15, weight: .medium))
                .tracking(0.2)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(bgColor)
                .foregroundColor(fgColor)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(strokeColor, lineWidth: variant == .secondary ? 1 : 0))
        }
        .opacity(disabled ? 0.35 : 1)
        .buttonStyle(ScaleButtonStyle())
    }

    private var bgColor: Color {
        switch variant {
        case .primary:   return .lPlum
        case .secondary: return .clear
        case .ghost:     return .clear
        }
    }

    private var fgColor: Color {
        switch variant {
        case .primary:   return .lCream
        case .secondary: return .lPlum
        case .ghost:     return .lInk2
        }
    }

    private var strokeColor: Color {
        variant == .secondary ? .lPlum : .clear
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Chip
struct ChipButton: View {
    let label: String
    var selected: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(LFont.body(14.5))
                .tracking(0.05)
                .padding(.horizontal, 18)
                .frame(height: 44)
                .background(selected ? Color.lPlum : Color.clear)
                .foregroundColor(selected ? .lCream : .lInk)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(
                        selected ? Color.lPlum : Color(red: 42/255, green: 37/255, blue: 32/255).opacity(0.18),
                        lineWidth: 1
                    )
                )
        }
        .animation(.easeInOut(duration: 0.15), value: selected)
    }
}

// MARK: - Small tag chip (read-only, for phase foods)
struct TagChip: View {
    let label: String
    var background: Color = .lCream
    var foreground: Color = .lInk2
    var size: CGFloat = 12

    var body: some View {
        Text(label)
            .font(LFont.body(size))
            .padding(.horizontal, 11)
            .padding(.vertical, 5)
            .background(background)
            .foregroundColor(foreground)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.lRule, lineWidth: 1))
    }
}

// MARK: - Section header
struct SectionHeader: View {
    let eyebrow: String?
    let title: String?
    var actionLabel: String? = nil
    var actionHandler: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                if let e = eyebrow { Eyebrow(e) }
                if let t = title {
                    DisplayLabel(text: t, size: 22, italic: true)
                }
            }
            Spacer()
            if let label = actionLabel, let handler = actionHandler {
                Button(action: handler) {
                    Text("\(label) →")
                        .font(LFont.body(13))
                        .foregroundColor(.lInk3)
                }
            }
        }
        .padding(.bottom, 14)
    }
}

// MARK: - Rounded card background
struct CardBackground: ViewModifier {
    var radius: CGFloat = 22
    var background: Color = .lPaper
    func modify(content: Content) -> some View {
        content
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(Color.lRule, lineWidth: 1))
    }
}

extension View {
    func cardStyle(radius: CGFloat = 22, background: Color = .lPaper) -> some View {
        self
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(Color.lRule, lineWidth: 1))
    }
}
