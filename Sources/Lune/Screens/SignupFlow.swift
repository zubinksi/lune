import SwiftUI

// MARK: - Shared signup header
struct SignupHeaderView: View {
    let step: Int   // 0-indexed
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack {
            Button {
                appState.back()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .regular))
                    Text("Back")
                        .font(LFont.body(14))
                }
                .foregroundColor(.lInk2)
                .padding(6)
            }

            Spacer()

            ProgressDots(step: step, total: 3)

            Spacer()

            // Balance spacer matching back button width ~56pt
            Color.clear.frame(width: 56, height: 1)
        }
        .padding(.top, 70)
        .padding(.horizontal, 24)
    }
}

// MARK: - Progress dots
struct ProgressDots: View {
    let step: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i <= step ? Color.lPlum : Color(red: 42/255, green: 37/255, blue: 32/255).opacity(0.15))
                    .frame(width: i == step ? 22 : 6, height: 6)
                    .animation(.easeInOut(duration: 0.25), value: step)
            }
        }
    }
}

// MARK: - Symptom step
let kSymptoms = ["Bloating", "Mood swings", "Cramping", "Cravings", "Sleeplessness", "Fatigue"]
let kDiets = ["Vegetarian", "Vegan", "Pescatarian", "No dairy", "No nuts", "More fruit", "More veg", "More protein"]

struct SignupSymptomsScreen: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            SignupHeaderView(step: 0)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Eyebrow("Step 1 of 3")

                    Spacer().frame(height: 12)

                    VStack(alignment: .leading, spacing: 0) {
                        Text("What would you")
                            .font(LFont.display(36))
                        Text("like to ") + Text("soften?").font(LFont.display(36, italic: true))
                    }
                    .font(LFont.display(36))
                    .tracking(-0.4)
                    .foregroundColor(.lInk)

                    Spacer().frame(height: 12)

                    BodyText(text: "Pick anything that's been showing up for you. We'll shape meal suggestions around easing it.")

                    Spacer().frame(height: 28)

                    FlowLayout(spacing: 8) {
                        ForEach(kSymptoms, id: \.self) { s in
                            ChipButton(
                                label: s,
                                selected: appState.profile.symptoms.contains(s)
                            ) {
                                toggleSymptom(s)
                            }
                        }
                    }

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 28)
                .padding(.top, 32)
            }

            VStack {
                PillButton(label: "Continue", disabled: appState.profile.symptoms.isEmpty) {
                    appState.advance()
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(Color.lCream.ignoresSafeArea())
    }

    private func toggleSymptom(_ s: String) {
        if appState.profile.symptoms.contains(s) {
            appState.profile.symptoms.removeAll { $0 == s }
        } else {
            appState.profile.symptoms.append(s)
        }
    }
}

// MARK: - Dietary step
struct SignupDietScreen: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            SignupHeaderView(step: 1)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Eyebrow("Step 2 of 3")
                    Spacer().frame(height: 12)

                    VStack(alignment: .leading, spacing: 0) {
                        Text("How do you")
                            .font(LFont.display(36))
                        Text("like to eat?").font(LFont.display(36, italic: true))
                    }
                    .tracking(-0.4)
                    .foregroundColor(.lInk)

                    Spacer().frame(height: 12)

                    BodyText(text: "Restrictions, preferences, what you want more of — pick anything that's true.")

                    Spacer().frame(height: 28)

                    FlowLayout(spacing: 8) {
                        ForEach(kDiets, id: \.self) { d in
                            ChipButton(
                                label: d,
                                selected: appState.profile.diet.contains(d)
                            ) {
                                toggleDiet(d)
                            }
                        }
                    }

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 28)
                .padding(.top, 32)
            }

            VStack {
                PillButton(label: "Continue") {
                    appState.advance()
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(Color.lCream.ignoresSafeArea())
    }

    private func toggleDiet(_ d: String) {
        if appState.profile.diet.contains(d) {
            appState.profile.diet.removeAll { $0 == d }
        } else {
            appState.profile.diet.append(d)
        }
    }
}

// MARK: - Notes step
struct SignupNotesScreen: View {
    @EnvironmentObject var appState: AppState
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            SignupHeaderView(step: 2)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Eyebrow("Step 3 of 3")
                    Spacer().frame(height: 12)

                    VStack(alignment: .leading, spacing: 0) {
                        Text("Anything")
                            .font(LFont.display(36))
                        Text("else?").font(LFont.display(36, italic: true))
                    }
                    .tracking(-0.4)
                    .foregroundColor(.lInk)

                    Spacer().frame(height: 12)

                    BodyText(text: "Allergies, cravings you can't quit, things you'd love more of. Lune will keep these in mind.")

                    Spacer().frame(height: 22)

                    // Name field
                    Eyebrow("Your name")
                    Spacer().frame(height: 8)
                    TextField("e.g. Genesha", text: $appState.profile.name)
                        .font(LFont.body(15))
                        .foregroundColor(.lInk)
                        .padding(18)
                        .background(Color.lPaper)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.lRule, lineWidth: 1))

                    Spacer().frame(height: 18)

                    ZStack(alignment: .topLeading) {
                        if appState.profile.notes.isEmpty {
                            Text("e.g. I really miss soft-boiled eggs in the morning…")
                                .font(LFont.body(15))
                                .foregroundColor(.lInk3)
                                .italic()
                                .padding(18)
                                .allowsHitTesting(false)
                        }

                        TextEditor(text: $appState.profile.notes)
                            .font(LFont.body(15))
                            .foregroundColor(.lInk)
                            .scrollContentBackground(.hidden)
                            .padding(18)
                            .frame(minHeight: 160)
                            .focused($focused)
                    }
                    .background(Color.lPaper)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.lRule, lineWidth: 1))

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 28)
                .padding(.top, 32)
            }

            VStack {
                PillButton(label: "Begin") {
                    appState.advance()
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(Color.lCream.ignoresSafeArea())
    }
}

// MARK: - Flow Layout (wrap chips)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        y += rowHeight
        return CGSize(width: maxWidth, height: y)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        let maxX = bounds.maxX

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxX, x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
