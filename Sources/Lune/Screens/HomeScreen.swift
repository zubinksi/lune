import SwiftUI

// MARK: - Home Screen
struct HomeScreen: View {
    @EnvironmentObject var appState: AppState

    private var phase: CyclePhaseInfo { appState.phaseInfo }
    private var phaseColor: Color { Color.phase(named: phase.name) }
    private var recipes: [Recipe] { defaultRecipes[phase.name] ?? defaultRecipes["Luteal"]! }

    // Silently refresh from HealthKit each time the dashboard appears
    private func refreshIfNeeded() {
        guard appState.profile.healthKitConnected else { return }
        Task { await appState.loadCycleData() }
    }

    private var dateStr: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, MMMM d"
        return fmt.string(from: Date()).uppercased()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                topBar
                greeting
                moonHero
                phaseNameAndStrip
                phaseCard
                divider(32)
                moodCheckIn
                divider(32)
                nourishmentSection
                divider(32)
                CraveSearchSection()
                divider(32)
                symptomLogSection
                divider(24)
                footer
                Spacer().frame(height: 60)
            }
        }
        .background(Color.lCream.ignoresSafeArea())
        .onAppear { refreshIfNeeded() }
    }

    // MARK: - Top bar
    var topBar: some View {
        HStack {
            Eyebrow(dateStr)
            Spacer()
            Button {} label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(.lInk2)
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 70)
    }

    // MARK: - Greeting
    var greeting: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Good morning,")
                .font(LFont.display(32))
                .foregroundColor(.lInk)
            Text("\(appState.profile.name).")
                .font(LFont.display(32, italic: true))
                .foregroundColor(.lInk)
        }
        .tracking(-0.4)
        .padding(.horizontal, 28)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Moon hero
    var moonHero: some View {
        ZStack {
            MoonView(
                phase: phase.phase,
                size: 220,
                litColor: .lInk,
                darkColor: .lCream2,
                showCraters: true,
                showGlow: false
            )

            VStack(spacing: 4) {
                Text("DAY")
                    .font(LFont.mono(10))
                    .tracking(2)
                    .foregroundColor(.lCream.opacity(0.85))
                Text("\(appState.cycleDay)")
                    .font(LFont.display(56))
                    .foregroundColor(.lCream)
                    .tracking(0)
                Text("of \(appState.cycleLength)")
                    .font(LFont.mono(10))
                    .tracking(1.5)
                    .foregroundColor(.lCream.opacity(0.75))
            }
            .shadow(color: .black.opacity(0.45), radius: 8, x: 0, y: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Phase name + cycle strip
    var phaseNameAndStrip: some View {
        VStack(spacing: 16) {
            Text(phase.name)
                .font(LFont.display(28, italic: true))
                .foregroundColor(.lInk)

            CycleStripView(day: appState.cycleDay, length: appState.cycleLength)
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 8)
    }

    // MARK: - Phase education card
    @State private var phaseExpanded = false

    var phaseCard: some View {
        let explainer = phaseExplainer[phase.name] ?? ""
        let foods = phaseFoods[phase.name] ?? []

        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Eyebrow("Why this phase matters", color: phaseColor)
                Spacer()
                ZStack {
                    Circle().fill(Color.lCream).frame(width: 22, height: 22)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.lInk)
                        .rotationEffect(.degrees(phaseExpanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.25), value: phaseExpanded)
                }
            }

            Spacer().frame(height: 8)

            Text(explainer)
                .font(LFont.body(14))
                .foregroundColor(.lInk)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(phaseExpanded ? nil : 2)
                .animation(.easeInOut(duration: 0.28), value: phaseExpanded)

            if phaseExpanded {
                Spacer().frame(height: 14)
                Divider().background(Color.lRule)
                Spacer().frame(height: 14)
                Eyebrow("Lean into")
                Spacer().frame(height: 8)
                FlowLayout(spacing: 6) {
                    ForEach(foods, id: \.self) { food in
                        TagChip(label: food, background: .lCream)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .cardStyle()
        .padding(.horizontal, 28)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.28)) {
                phaseExpanded.toggle()
            }
        }
    }

    // MARK: - Mood check-in
    var moodCheckIn: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(eyebrow: "Today's check-in", title: "How are you feeling?")

            HStack(spacing: 8) {
                ForEach(["Steady", "Tender", "Tired", "Bright", "Bloated"], id: \.self) { m in
                    MoodOptionButton(label: m, selected: appState.dailyLog.mood == m) {
                        appState.dailyLog.mood = appState.dailyLog.mood == m ? nil : m
                    }
                }
            }

            if let mood = appState.dailyLog.mood {
                HStack {
                    Text(moodResponse(mood))
                        .font(LFont.body(13))
                        .foregroundColor(.lSageDeep)
                        .lineSpacing(3)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 138/255, green: 154/255, blue: 122/255).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(red: 138/255, green: 154/255, blue: 122/255).opacity(0.25), lineWidth: 1))
                .padding(.top, 14)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 28)
        .animation(.easeInOut(duration: 0.18), value: appState.dailyLog.mood)
    }

    private func moodResponse(_ mood: String) -> String {
        switch mood {
        case "Bloated":  return "Got it — we'll lean on fennel, ginger, and lighter proteins today."
        case "Tired":    return "Today's picks will lean heavier on iron and complex carbs."
        case "Tender":   return "Warming, magnesium-rich meals coming up. Soft on the system."
        case "Steady":   return "Lovely. We'll stay the course with \(phase.name.lowercased())-friendly staples."
        case "Bright":   return "Beautiful — riding the wave. We'll keep things balanced."
        default:         return ""
        }
    }

    // MARK: - Nourishment
    var nourishmentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(eyebrow: "Today", title: "Nourishment",
                          actionLabel: "See all", actionHandler: {})

            VStack(spacing: 10) {
                ForEach(recipes) { recipe in
                    RecipeCard(recipe: recipe)
                }
            }
        }
        .padding(.horizontal, 28)
    }

    // MARK: - Symptom log
    @State private var savedSymptom: String? = nil

    var symptomLogSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(eyebrow: "Symptom log", title: "How is today?")

            VStack(alignment: .leading, spacing: 0) {
                Text("Cramping compared to yesterday?")
                    .font(LFont.body(13.5))
                    .foregroundColor(.lInk)
                    .padding(.bottom, 14)

                HStack(spacing: 8) {
                    ForEach(["Worse", "Same", "Better"], id: \.self) { o in
                        Button {
                            savedSymptom = o
                        } label: {
                            Text(o)
                                .font(LFont.body(13.5))
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(savedSymptom == o ? Color.lPlum : Color.clear)
                                .foregroundColor(savedSymptom == o ? .lCream : .lInk)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(savedSymptom == o ? Color.lPlum : Color.lRule, lineWidth: 1))
                        }
                        .animation(.easeInOut(duration: 0.15), value: savedSymptom)
                    }
                }

                if savedSymptom != nil {
                    Text("Logged. Lune will keep adjusting based on what's helping.")
                        .font(LFont.body(12))
                        .italic()
                        .foregroundColor(.lInk3)
                        .padding(.top, 12)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 18)
            .cardStyle()
        }
        .animation(.easeInOut(duration: 0.18), value: savedSymptom)
        .padding(.horizontal, 28)
    }

    // MARK: - Footer
    var footer: some View {
        Eyebrow("Ona · with the moon", color: .lInk3)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 8)
    }

    private func divider(_ h: CGFloat) -> some View {
        Spacer().frame(height: h)
    }
}

// MARK: - Mood option button
struct MoodOptionButton: View {
    let label: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(LFont.body(13))
                .tracking(0.1)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(selected ? Color.lPlum : Color.lPaper)
                .foregroundColor(selected ? .lCream : .lInk)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected ? Color.lPlum : Color.lRule, lineWidth: 1))
        }
        .animation(.easeInOut(duration: 0.18), value: selected)
    }
}

// MARK: - Recipe card
struct RecipeCard: View {
    let recipe: Recipe
    @State private var isSaved = false

    var iconColor: Color {
        switch recipe.icon {
        case "salmon": return .lTerracottaDeep
        case "leaf":   return .lSage
        default:       return .lTerracotta
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Icon tile
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.lCream)
                    .frame(width: 64, height: 64)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.lRule, lineWidth: 1))
                FoodIconView(kind: recipe.icon, size: 42, color: iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Eyebrow(recipe.time.uppercased())
                Text(recipe.name)
                    .font(LFont.displayRegular(19))
                    .foregroundColor(.lInk)
                    .lineSpacing(2)
                BodyText(text: recipe.why, size: 12.5)
                    .lineSpacing(2)
            }

            Spacer(minLength: 0)

            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.lInk)
                .padding(.top, 4)
                .onTapGesture { isSaved.toggle() }
        }
        .padding(18)
        .cardStyle()
    }
}

// MARK: - Cycle strip
struct CycleStripView: View {
    let day: Int
    let length: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...length, id: \.self) { d in
                let info = cyclePhase(day: d, length: length)
                let isToday = d == day
                VStack(spacing: 6) {
                    MoonIcon(
                        phase: info.phase,
                        size: isToday ? 14 : 10,
                        litColor: .lInk,
                        darkColor: Color(red: 42/255, green: 37/255, blue: 32/255).opacity(0.12)
                    )
                    if isToday {
                        Circle()
                            .fill(Color.lTerracotta)
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
