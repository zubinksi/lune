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

            ProgressDots(step: step, total: 5)

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
let kCookingStyles = [
    "Bold & spiced", "Bright & acidic", "Herb-forward", "Smoky & charred", "Warm & aromatic",
    "Lots of vegetables", "Legume & grain heavy", "Seafood-forward",
    "Slow-cooked & brothy", "Quick & high-heat", "One-pan, low-effort"
]

struct SignupSymptomsScreen: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            SignupHeaderView(step: 0)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Eyebrow("Step 1 of 5")

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
                .padding(.horizontal, 24)
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
                    Eyebrow("Step 2 of 5")
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
                .padding(.horizontal, 24)
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

// MARK: - Cooking style step
struct SignupCookingStyleScreen: View {
    @EnvironmentObject var appState: AppState
    @FocusState private var notesFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            SignupHeaderView(step: 2)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Eyebrow("Step 3 of 5")
                    Spacer().frame(height: 12)

                    VStack(alignment: .leading, spacing: 0) {
                        Text("How do you")
                            .font(LFont.display(36))
                        Text("like to cook?").font(LFont.display(36, italic: true))
                    }
                    .tracking(-0.4)
                    .foregroundColor(.lInk)

                    Spacer().frame(height: 12)

                    BodyText(text: "Pick what resonates. These shape the flavour and style of every recipe Ona suggests.")

                    Spacer().frame(height: 28)

                    FlowLayout(spacing: 8) {
                        ForEach(kCookingStyles, id: \.self) { s in
                            ChipButton(
                                label: s,
                                selected: appState.profile.cookingStyles.contains(s)
                            ) {
                                if appState.profile.cookingStyles.contains(s) {
                                    appState.profile.cookingStyles.removeAll { $0 == s }
                                } else {
                                    appState.profile.cookingStyles.append(s)
                                }
                            }
                        }
                    }

                    Spacer().frame(height: 24)

                    Eyebrow("Anything else?")
                    Spacer().frame(height: 8)

                    ZStack(alignment: .topLeading) {
                        if appState.profile.cookingStyleNotes.isEmpty {
                            Text("e.g. I love Ottolenghi, always come back to tahini and lemon…")
                                .font(LFont.body(14))
                                .foregroundColor(.lInk3)
                                .italic()
                                .padding(16)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $appState.profile.cookingStyleNotes)
                            .font(LFont.body(14))
                            .foregroundColor(.lInk)
                            .scrollContentBackground(.hidden)
                            .padding(12)
                            .frame(minHeight: 100)
                            .focused($notesFocused)
                    }
                    .background(Color.lPaper)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.lRule, lineWidth: 1))

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
            }

            VStack {
                PillButton(label: "Continue") {
                    notesFocused = false
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

// MARK: - Name step
struct SignupNotesScreen: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            SignupHeaderView(step: 3)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Eyebrow("Step 4 of 5")
                    Spacer().frame(height: 12)

                    VStack(alignment: .leading, spacing: 0) {
                        Text("What should")
                            .font(LFont.display(36))
                        Text("Ona call you?").font(LFont.display(36, italic: true))
                    }
                    .tracking(-0.4)
                    .foregroundColor(.lInk)

                    Spacer().frame(height: 12)

                    BodyText(text: "Ona will use your name to make recommendations feel personal.")

                    Spacer().frame(height: 28)

                    TextField("e.g. Genesha", text: $appState.profile.name)
                        .font(LFont.body(15))
                        .foregroundColor(.lInk)
                        .padding(18)
                        .background(Color.lPaper)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.lRule, lineWidth: 1))

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 24)
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
}

// MARK: - API Key step
struct SignupAPIKeyScreen: View {
    @EnvironmentObject var appState: AppState
    @State private var apiKey: String = UserDefaults.standard.string(forKey: "anthropicAPIKey") ?? ""
    @State private var apiKeyVisible = false

    var body: some View {
        VStack(spacing: 0) {
            SignupHeaderView(step: 4)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Eyebrow("Step 5 of 5")
                    Spacer().frame(height: 12)

                    VStack(alignment: .leading, spacing: 0) {
                        Text("Power up")
                            .font(LFont.display(36))
                        Text("the AI.").font(LFont.display(36, italic: true))
                    }
                    .tracking(-0.4)
                    .foregroundColor(.lInk)

                    Spacer().frame(height: 12)

                    BodyText(text: "Ona uses Anthropic's Claude to generate your daily nourishment and recipe suggestions. Add your API key to unlock these features.")

                    Spacer().frame(height: 28)

                    Eyebrow("Anthropic API key")
                    Spacer().frame(height: 8)

                    HStack(spacing: 0) {
                        Group {
                            if apiKeyVisible {
                                TextField("sk-ant-...", text: $apiKey)
                            } else {
                                SecureField("sk-ant-...", text: $apiKey)
                            }
                        }
                        .font(LFont.body(14))
                        .foregroundColor(.lInk)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onChange(of: apiKey) { _, val in
                            UserDefaults.standard.set(val.trimmingCharacters(in: .whitespaces), forKey: "anthropicAPIKey")
                        }

                        Button {
                            apiKeyVisible.toggle()
                        } label: {
                            Image(systemName: apiKeyVisible ? "eye.slash" : "eye")
                                .font(.system(size: 14))
                                .foregroundColor(.lInk3)
                                .padding(.leading, 10)
                        }
                    }
                    .padding(16)
                    .background(Color.lPaper)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.lRule, lineWidth: 1))

                    Spacer().frame(height: 8)
                    Text("Your key is stored only on this device and never shared.")
                        .font(LFont.body(12))
                        .foregroundColor(.lInk3)

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
            }

            VStack(spacing: 12) {
                PillButton(label: "Begin") {
                    appState.advance()
                }
                Button {
                    appState.advance()
                } label: {
                    Text("Skip for now")
                        .font(LFont.body(13.5))
                        .foregroundColor(.lInk3)
                        .frame(maxWidth: .infinity)
                        .padding(12)
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
