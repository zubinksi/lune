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

    @State private var showSettings = false

    private var hasAPIKey: Bool {
        !(UserDefaults.standard.string(forKey: "anthropicAPIKey") ?? "").isEmpty
    }

    private var dateStr: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, MMMM d"
        return fmt.string(from: Date()).uppercased()
    }

    private var hebrewDateStr: String {
        let fmt = DateFormatter()
        fmt.calendar = Calendar(identifier: .hebrew)
        fmt.locale = Locale(identifier: "en_US")
        fmt.dateFormat = "d MMMM"
        return fmt.string(from: Date())
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
                if hasAPIKey {
                    divider(32)
                    CraveSearchSection()
                }
                divider(32)
                cycleHistoryCard
                divider(32)
                partnerShare
                divider(24)
                footer
                Spacer().frame(height: 60)
            }
        }
        .background(Color.lCream.ignoresSafeArea())
        .onAppear {
            refreshIfNeeded()
            Task { await appState.loadDailyNourishment() }
        }
        .sheet(isPresented: $showSettings) {
            SettingsScreen()
                .environmentObject(appState)
        }
    }

    // MARK: - Top bar
    var topBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Eyebrow(dateStr)
                Text(hebrewDateStr)
                    .font(LFont.mono(9))
                    .tracking(0.5)
                    .foregroundColor(.lInk3)
            }
            Spacer()
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(.lInk2)
            }
        }
        .padding(.horizontal, 50)
        .padding(.top, 70)
    }

    private var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning,"
        case 12..<17: return "Good afternoon,"
        default: return "Good evening,"
        }
    }

    // MARK: - Greeting
    var greeting: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(timeOfDayGreeting)
                .font(LFont.display(32))
                .foregroundColor(.lInk)
            Text("\(appState.profile.name).")
                .font(LFont.display(32, italic: true))
                .foregroundColor(.lInk)
        }
        .tracking(-0.4)
        .padding(.horizontal, 50)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Moon hero
    var moonHero: some View {
        // Near new moon (phase < 0.12 or > 0.88): disk is mostly cream — use dark text
        let onDarkMoon = phase.phase >= 0.12 && phase.phase <= 0.88
        let textColor: Color = onDarkMoon ? .lCream : .lInk
        let shadowColor: Color = onDarkMoon ? .black.opacity(0.45) : .white.opacity(0.5)

        return ZStack {
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
                    .foregroundColor(textColor.opacity(0.75))
                Text("\(appState.cycleDay)")
                    .font(LFont.display(56))
                    .foregroundColor(textColor)
                    .tracking(0)
                Text("of \(appState.cycleLength)")
                    .font(LFont.mono(10))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.65))
            }
            .shadow(color: shadowColor, radius: 8, x: 0, y: 0)
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
        .padding(.horizontal, 50)
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
        .padding(.horizontal, 50)
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
        .padding(.horizontal, 50)
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
            SectionHeader(eyebrow: "Today", title: "Nourishment")

            if appState.nourishmentLoading && appState.dailyNourishment.isEmpty {
                // First-load skeleton
                HStack(spacing: 12) {
                    SpinnerView()
                    Text("Preparing today's nourishment…")
                        .font(LFont.body(14))
                        .foregroundColor(.lInk2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .cardStyle()
            } else {
                let cards = appState.dailyNourishment.isEmpty ? recipes : appState.dailyNourishment
                VStack(spacing: 10) {
                    ForEach(cards) { recipe in
                        NourishmentCard(recipe: recipe, currentPhase: phase.name)
                    }
                }
            }
        }
        .padding(.horizontal, 50)
    }

    // MARK: - Cycle history (saved recipes from this phase)
    @State private var selectedSavedRecipe: Recipe? = nil

    var cycleHistoryCard: some View {
        let phaseRecipes = appState.savedRecipes.filter { $0.phase == phase.name }

        return VStack(alignment: .leading, spacing: 0) {
            SectionHeader(eyebrow: "From last cycle")

            ZStack(alignment: .topTrailing) {
                Color.lInk
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                MoonView(phase: 0.65, size: 160, litColor: .lCream, darkColor: .lInk,
                         showCraters: false, showGlow: false)
                    .opacity(0.15)
                    .offset(x: 40, y: -30)
                    .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: 0) {
                    if phaseRecipes.isEmpty {
                        Eyebrow("Nothing saved yet", color: Color.lCream.opacity(0.55))
                        Spacer().frame(height: 10)
                        Text("Bookmark a recipe during your \(phase.name.lowercased()) phase and it'll live here for next time.")
                            .font(LFont.body(14))
                            .foregroundColor(Color.lCream.opacity(0.8))
                            .lineSpacing(4)
                            .frame(maxWidth: 270, alignment: .leading)
                    } else {
                        Eyebrow("Saved this phase", color: Color.lCream.opacity(0.55))
                        Spacer().frame(height: 10)
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(phaseRecipes.prefix(3)) { r in
                                Button { selectedSavedRecipe = r } label: {
                                    HStack {
                                        Text(r.name)
                                            .font(LFont.displayRegular(17))
                                            .foregroundColor(.lCream)
                                            .lineSpacing(2)
                                            .multilineTextAlignment(.leading)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 11))
                                            .foregroundColor(Color.lCream.opacity(0.45))
                                    }
                                    .padding(.vertical, 8)
                                }
                                .buttonStyle(.plain)
                                if r.id != phaseRecipes.prefix(3).last?.id {
                                    Divider().background(Color.lCream.opacity(0.15))
                                }
                            }
                        }
                        if phaseRecipes.count > 3 {
                            Spacer().frame(height: 10)
                            Text("+ \(phaseRecipes.count - 3) more saved")
                                .font(LFont.mono(10))
                                .tracking(0.8)
                                .foregroundColor(Color.lCream.opacity(0.45))
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 22)
            }
        }
        .padding(.horizontal, 50)
        .sheet(item: $selectedSavedRecipe) { r in
            SavedRecipeSheet(recipe: r)
                .environmentObject(appState)
        }
    }

    // MARK: - Partner share
    var partnerShare: some View {
        let name = appState.profile.name
        let foods = phaseFoods[phase.name]?.joined(separator: ", ") ?? ""
        let shareText = "\(name) is in her \(phase.name.lowercased()) phase today (day \(appState.cycleDay) of \(appState.cycleLength)).\n\nOna recommends: \(foods).\n\nOna — cycle nutrition, shaped around her."

        return ShareLink(item: shareText) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.lCream2)
                        .frame(width: 44, height: 44)
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.lInk)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("For your partner")
                        .font(LFont.display(18, italic: true))
                        .foregroundColor(.lInk)
                    BodyText(text: "A gentle \"what to cook for her this week\" summary.", size: 12.5)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.lInk2)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    .foregroundColor(Color.lRule)
            )
        }
        .padding(.horizontal, 50)
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
    let currentPhase: String
    @EnvironmentObject var appState: AppState

    var isSaved: Bool {
        appState.savedRecipes.contains { $0.name == recipe.name }
    }

    var iconColor: Color {
        switch recipe.icon {
        case "salmon": return .lTerracottaDeep
        case "leaf":   return .lSage
        default:       return .lTerracotta
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
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
                .foregroundColor(isSaved ? .lPlum : .lInk)
                .padding(.top, 4)
                .onTapGesture {
                    if isSaved {
                        appState.savedRecipes.removeAll { $0.name == recipe.name }
                    } else {
                        var r = recipe
                        r.phase = currentPhase
                        appState.savedRecipes.append(r)
                    }
                }
                .animation(.easeInOut(duration: 0.15), value: isSaved)
        }
        .padding(18)
        .cardStyle()
    }
}

// MARK: - Nourishment card (expandable, with full recipe)
struct NourishmentCard: View {
    let recipe: Recipe
    let currentPhase: String
    @EnvironmentObject var appState: AppState
    @State private var expanded = false

    var isSaved: Bool {
        appState.savedRecipes.contains { $0.name == recipe.name }
    }

    var iconColor: Color {
        switch recipe.icon {
        case "salmon": return .lTerracottaDeep
        case "leaf":   return .lSage
        default:       return .lTerracotta
        }
    }

    var hasDetail: Bool { !recipe.ingredients.isEmpty || !recipe.steps.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Header row — always visible, tap to expand
            Button {
                guard hasDetail else { return }
                withAnimation(.easeInOut(duration: 0.22)) { expanded.toggle() }
            } label: {
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.lCream)
                            .frame(width: 64, height: 64)
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.lRule, lineWidth: 1))
                        FoodIconView(kind: recipe.icon, size: 42, color: iconColor)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Eyebrow(recipe.time.uppercased())
                        Text(recipe.name)
                            .font(LFont.displayRegular(19))
                            .foregroundColor(.lInk)
                            .lineSpacing(2)
                            .multilineTextAlignment(.leading)
                        BodyText(text: recipe.why, size: 12.5)
                            .lineSpacing(2)
                    }

                    Spacer(minLength: 0)

                    VStack(alignment: .trailing, spacing: 10) {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(isSaved ? .lPlum : .lInk)
                            .onTapGesture {
                                if isSaved {
                                    appState.savedRecipes.removeAll { $0.name == recipe.name }
                                } else {
                                    var r = recipe
                                    r.phase = currentPhase
                                    appState.savedRecipes.append(r)
                                }
                            }
                            .animation(.easeInOut(duration: 0.15), value: isSaved)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.lInk3)
                            .rotationEffect(.degrees(expanded ? 180 : 0))
                            .animation(.easeInOut(duration: 0.22), value: expanded)
                            .opacity(hasDetail ? 1 : 0)
                    }
                    .padding(.top, 4)
                }
            }
            .buttonStyle(.plain)

            // Expanded detail
            if expanded && (!recipe.ingredients.isEmpty || !recipe.steps.isEmpty) {
                VStack(alignment: .leading, spacing: 0) {
                    Divider()
                        .background(Color.lRule)
                        .padding(.vertical, 14)

                    if !recipe.ingredients.isEmpty {
                        Eyebrow("Ingredients")
                        Spacer().frame(height: 10)
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(recipe.ingredients, id: \.self) { item in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle()
                                        .fill(Color.lInk3)
                                        .frame(width: 4, height: 4)
                                        .padding(.top, 6)
                                    Text(item)
                                        .font(LFont.body(13.5))
                                        .foregroundColor(.lInk2)
                                        .lineSpacing(2)
                                }
                            }
                        }
                        Spacer().frame(height: 16)
                    }

                    if !recipe.steps.isEmpty {
                        Eyebrow("How to make it")
                        Spacer().frame(height: 10)
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(Array(recipe.steps.enumerated()), id: \.offset) { i, step in
                                HStack(alignment: .top, spacing: 10) {
                                    Text("\(i + 1)")
                                        .font(LFont.mono(10))
                                        .tracking(0.5)
                                        .foregroundColor(.lInk3)
                                        .frame(width: 16, alignment: .trailing)
                                        .padding(.top, 3)
                                    Text(step)
                                        .font(LFont.body(13.5))
                                        .foregroundColor(.lInk2)
                                        .lineSpacing(3)
                                }
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(18)
        .cardStyle()
    }
}

// MARK: - Saved recipe detail sheet
struct SavedRecipeSheet: View {
    let recipe: Recipe
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            Color.lCream.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: 80)

                    Eyebrow(recipe.time.uppercased())
                    Spacer().frame(height: 8)
                    Text(recipe.name)
                        .font(LFont.display(28))
                        .foregroundColor(.lInk)
                        .lineSpacing(3)
                    Spacer().frame(height: 8)
                    BodyText(text: recipe.why, size: 14)
                    Spacer().frame(height: 28)

                    if !recipe.ingredients.isEmpty {
                        Eyebrow("Ingredients")
                        Spacer().frame(height: 12)
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(recipe.ingredients, id: \.self) { item in
                                HStack(alignment: .top, spacing: 10) {
                                    Circle()
                                        .fill(Color.lTerracotta)
                                        .frame(width: 4, height: 4)
                                        .padding(.top, 7)
                                    Text(item)
                                        .font(LFont.body(14))
                                        .foregroundColor(.lInk2)
                                        .lineSpacing(2)
                                }
                            }
                        }
                        Spacer().frame(height: 28)
                    }

                    if !recipe.steps.isEmpty {
                        Eyebrow("Prep")
                        Spacer().frame(height: 12)
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(recipe.steps.indices, id: \.self) { i in
                                HStack(alignment: .top, spacing: 12) {
                                    Text(String(format: "%02d", i + 1))
                                        .font(LFont.mono(10))
                                        .tracking(1)
                                        .foregroundColor(.lInk3)
                                        .padding(.top, 3)
                                    Text(recipe.steps[i])
                                        .font(LFont.body(14))
                                        .foregroundColor(.lInk2)
                                        .lineSpacing(2)
                                }
                            }
                        }
                        Spacer().frame(height: 28)
                    }

                    Button {
                        appState.savedRecipes.removeAll { $0.name == recipe.name }
                        dismiss()
                    } label: {
                        Text("Remove bookmark")
                            .font(LFont.body(13))
                            .foregroundColor(.lRed.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.lPaper)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.lRed.opacity(0.2), lineWidth: 1))
                    }

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 50)
            }

            HStack {
                Text(recipe.phase.isEmpty ? "Saved recipe" : recipe.phase)
                    .font(LFont.display(20))
                    .foregroundColor(.lInk)
                Spacer()
                Button { dismiss() } label: {
                    Text("Done")
                        .font(LFont.body(15, weight: .medium))
                        .foregroundColor(.lPlum)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.lCream)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.lRule, lineWidth: 1))
                }
            }
            .padding(.horizontal, 50)
            .padding(.top, 20)
            .background(
                Color.lCream
                    .ignoresSafeArea(edges: .top)
                    .shadow(color: Color.lInk.opacity(0.04), radius: 8, x: 0, y: 4)
            )
        }
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
