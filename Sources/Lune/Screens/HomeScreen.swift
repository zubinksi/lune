import SwiftUI

// MARK: - Home Screen
struct HomeScreen: View {
    @EnvironmentObject var appState: AppState

    @State private var showSettings = false
    @State private var showSavedRecipes = false
    @State private var showTellOna = false
    @State private var homecraving = ""
    @FocusState private var cravingFocused: Bool

    private var phase: CyclePhaseInfo { appState.phaseInfo }
    private var isComposed: Bool { !appState.dailyNourishment.isEmpty }

    private var hasProxy: Bool { !ProxyConfig.proxyURL.contains("your-subdomain") }
    private var hasAPIKey: Bool { !(UserDefaults.standard.string(forKey: "anthropicAPIKey") ?? "").isEmpty }
    private var aiEnabled: Bool { hasProxy || hasAPIKey }

    private func refreshIfNeeded() {
        guard appState.profile.healthKitConnected else { return }
        Task { await appState.loadCycleData() }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                topBar
                greetingHeader
                Spacer().frame(height: 32)

                if isComposed {
                    composedFromSection
                    Spacer().frame(height: 16)
                    if !appState.dailySummary.isEmpty {
                        onaReadCard
                        Spacer().frame(height: 24)
                    }
                } else {
                    timeline
                    Spacer().frame(height: 8)
                    if aiEnabled { composeCTA }
                    Spacer().frame(height: 24)
                }

                recipesSection
                Spacer().frame(height: 32)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            tabBar
                .background(Color.lCream.ignoresSafeArea(edges: .bottom))
                .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .background(Color.lCream.ignoresSafeArea())
        .onAppear {
            refreshIfNeeded()
            if appState.dailyLog.mood != nil && appState.dailyNourishment.isEmpty {
                Task { await appState.loadDailyNourishment() }
            }
        }
        .sheet(isPresented: $showSavedRecipes) {
            SavedRecipesLibrarySheet().environmentObject(appState)
        }
        .sheet(isPresented: $showSettings) {
            SettingsScreen().environmentObject(appState)
        }
        .sheet(isPresented: $showTellOna) {
            TellOnaSheet().environmentObject(appState)
        }
    }

    // MARK: - Top bar
    var topBar: some View {
        HStack(spacing: 6) {
            Text(appState.currentSeason().uppercased())
                .font(LFont.mono(10))
                .tracking(1.2)
                .foregroundColor(.lInk3)
            Text("MENU")
                .font(LFont.mono(10))
                .tracking(1.2)
                .foregroundColor(.lInk3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 14)
        .padding(.bottom, 4)
    }

    // MARK: - Greeting
    var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(greetingLine)
                .font(LFont.display(38))
                .foregroundColor(.lInk)
            let name = appState.profile.name
            if !name.isEmpty {
                Text(name + ".")
                    .font(LFont.display(38, italic: true))
                    .foregroundColor(.lInk)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 2)
    }

    private var greetingLine: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 0..<12: return "Good morning,"
        case 12..<17: return "Good afternoon,"
        default:     return "Good evening,"
        }
    }

    // MARK: - Timeline feed
    var timeline: some View {
        VStack(alignment: .leading, spacing: 0) {
            moodRow
            phaseRow
            cravingRow
        }
    }

    // MARK: MOOD row
    var moodRow: some View {
        HStack(alignment: .top, spacing: 0) {
            threadColumn(dot: Color.lPlum, isLast: false)

            VStack(alignment: .leading, spacing: 8) {
                Eyebrow("Mood")
                if let mood = appState.dailyLog.mood {
                    HStack(spacing: 8) {
                        Text(mood)
                            .font(LFont.display(22))
                            .foregroundColor(.lInk)
                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) { appState.dailyLog.mood = nil }
                        } label: {
                            Text("edit")
                                .font(LFont.body(12))
                                .foregroundColor(.lInk3)
                        }
                    }
                    Text(moodSubtext(mood))
                        .font(LFont.body(13))
                        .italic()
                        .foregroundColor(.lInk2)
                } else {
                    Text("How are you feeling today?")
                        .font(LFont.display(22, italic: true))
                        .foregroundColor(.lInk2)
                    Spacer().frame(height: 6)
                    HStack(spacing: 8) {
                        ForEach(["Steady", "Tender", "Tired", "Bloated"], id: \.self) { m in
                            Button {
                                withAnimation(.easeInOut(duration: 0.18)) { appState.dailyLog.mood = m }
                            } label: {
                                Text(m)
                                    .font(LFont.body(12))
                                    .foregroundColor(.lInk)
                                    .padding(.horizontal, 12)
                                    .frame(height: 34)
                                    .background(Color.lPaper)
                                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .stroke(Color.lRule, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.leading, 16)
            .padding(.bottom, 24)

        }
        .animation(.easeInOut(duration: 0.18), value: appState.dailyLog.mood)
    }

    // MARK: PHASE row
    var phaseRow: some View {
        HStack(alignment: .top, spacing: 0) {
            threadColumn(dot: Color.lTerracotta, isLast: false)

            VStack(alignment: .leading, spacing: 4) {
                Eyebrow("Phase")
                HStack(spacing: 10) {
                    Text("\(phase.name) · Day \(appState.cycleDay) of \(appState.cycleLength)")
                        .font(LFont.display(22))
                        .foregroundColor(.lInk)
                    MoonIcon(
                        phase: phase.phase,
                        size: 22,
                        litColor: .lPlumDeep,
                        darkColor: Color(red: 42/255, green: 37/255, blue: 32/255).opacity(0.07)
                    )
                }
                if let tagline = phaseTaglines[phase.name] {
                    Text(tagline)
                        .font(LFont.body(13))
                        .foregroundColor(.lInk3)
                }
            }
            .padding(.leading, 16)
            .padding(.bottom, 24)
        }
    }

    // MARK: CRAVING row
    var cravingRow: some View {
        HStack(alignment: .top, spacing: 0) {
            threadColumn(dot: Color(hex: "c9a85c"), isLast: true)

            VStack(alignment: .leading, spacing: 8) {
                Eyebrow("Notes")
                HStack(spacing: 6) {
                    if homecraving.isEmpty {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.lInk3)
                    }
                    TextField(text: $homecraving) {
                        Text("Cravings, on hand ingredients, etc.")
                            .font(LFont.display(20, italic: true))
                            .foregroundColor(.lInk3)
                    }
                    .font(LFont.display(20, italic: true))
                    .foregroundColor(.lInk)
                    .focused($cravingFocused)
                    .autocorrectionDisabled()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.lCream)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .foregroundColor(cravingFocused ? Color.lPlum.opacity(0.4) : Color(hex: "c9a85c").opacity(0.35)))
            }
            .padding(.leading, 16)
            .padding(.bottom, 8)
            .padding(.trailing, 24)
        }
    }

    // MARK: - Thread column (dot + connecting line)
    @ViewBuilder
    private func threadColumn(dot: Color, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            Circle()
                .fill(dot)
                .frame(width: 8, height: 8)
                .padding(.top, 5)
            if !isLast {
                Rectangle()
                    .fill(Color.lInk.opacity(0.1))
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: 8)
        .padding(.leading, 24)
    }

    // MARK: - Compose CTA (end of timeline)
    var composeCTA: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .stroke(Color.lInk.opacity(0.15), lineWidth: 1)
                        .frame(width: 12, height: 12)
                    Image(systemName: "plus")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(.lInk3)
                }
                .padding(.top, 2)
            }
            .frame(width: 12)
            .padding(.leading, 21)

            VStack(alignment: .leading, spacing: 10) {
                Eyebrow("Ready when you are")
                    .padding(.top, 1)

                Button {
                    cravingFocused = false
                    Task { await appState.loadDailyNourishment(craving: homecraving) }
                } label: {
                    Text("Compose today's meals")
                        .font(LFont.body(15, weight: .medium))
                        .foregroundColor(.lCream)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.lPlum)
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                }

                Text(appState.dailyLog.mood == nil
                    ? "Pick a mood — add a note first, if you like."
                    : "Add a note if you like, then compose.")
                    .font(LFont.body(12))
                    .foregroundColor(.lInk3)
                    .italic()
            }
            .padding(.leading, 14)
            .padding(.trailing, 24)
        }
    }

    // MARK: - Composed from section
    var composedFromSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("COMPOSED FROM")
                    .font(LFont.mono(9.5))
                    .tracking(1.2)
                    .foregroundColor(.lInk3)
                Spacer()
                Button { appState.clearNourishmentCache() } label: {
                    Text("TAP TO ADJUST")
                        .font(LFont.mono(9.5))
                        .tracking(1.2)
                        .foregroundColor(.lInk3)
                }
            }

            FlowLayout(spacing: 8) {
                if let mood = appState.dailyLog.mood {
                    composedChip(dot: .lPlum, label: mood, editable: true) {
                        appState.clearNourishmentCache()
                        withAnimation { appState.dailyLog.mood = nil }
                    }
                }
                composedChip(dot: .lTerracotta,
                    label: "\(phase.name) · \(appState.cycleDay)/\(appState.cycleLength)",
                    editable: false) {}
                composedChip(dot: .lSage, label: appState.currentSeason().capitalized, editable: false) {}
                composedChip(dot: .lTerracottaDeep, label: "Diet & Palate", editable: true) {
                    showSettings = true
                }
                if !homecraving.isEmpty {
                    composedChip(dot: Color(hex: "c9a85c"), label: "\u{201C}\(homecraving)\u{201D}", editable: true) {
                        homecraving = ""
                        appState.clearNourishmentCache()
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private func composedChip(dot: Color, label: String, editable: Bool, onEdit: @escaping () -> Void) -> some View {
        HStack(spacing: 6) {
            Circle().fill(dot).frame(width: 6, height: 6)
            Text(label)
                .font(LFont.body(13))
                .foregroundColor(.lInk)
            if editable {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.lInk3)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.lCream)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.lInk.opacity(0.08), lineWidth: 1))
    }

    // MARK: - Ona's Read for Today
    var onaReadCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.lInk)
                        .frame(width: 22, height: 22)
                    Image(systemName: "sparkle")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white)
                }
                Text("ONA'S READ FOR TODAY")
                    .font(LFont.mono(9.5))
                    .tracking(1.2)
                    .foregroundColor(.lInk3)
            }
            Text(appState.dailySummary)
                .font(LFont.display(20, italic: true))
                .foregroundColor(.lInk)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.lPaper)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(Color.lRule, lineWidth: 1))
        .padding(.horizontal, 24)
    }

    // MARK: - Recipes section
    var recipesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Today's meals")
                    .font(LFont.display(22))
                    .foregroundColor(.lInk)
                Spacer()
                Group {
                    if appState.nourishmentLoading {
                        Text("LOADING")
                            .foregroundColor(.lInk3)
                    } else if isComposed {
                        Text("COMPOSED")
                            .foregroundColor(.lPlum)
                    } else {
                        Text("AWAITING")
                            .foregroundColor(.lInk3)
                    }
                }
                .font(LFont.mono(9.5))
                .tracking(1.2)
            }
            .padding(.horizontal, 24)

            Spacer().frame(height: 16)

            if appState.nourishmentLoading && appState.dailyNourishment.isEmpty {
                HStack(spacing: 12) {
                    SpinnerView()
                    Text("Composing your meals…")
                        .font(LFont.body(14))
                        .italic()
                        .foregroundColor(.lInk2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .cardStyle()
                .padding(.horizontal, 24)
            } else if let err = appState.nourishmentError {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Couldn't compose meals")
                        .font(LFont.body(13, weight: .medium))
                        .foregroundColor(.lRed)
                    Text(err)
                        .font(LFont.body(12))
                        .foregroundColor(.lRed.opacity(0.7))
                        .lineSpacing(2)
                    Button {
                        appState.nourishmentError = nil
                        Task { await appState.loadDailyNourishment(craving: homecraving) }
                    } label: {
                        Text("Try again")
                            .font(LFont.body(12.5, weight: .medium))
                            .foregroundColor(.lPlum)
                    }
                    .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .cardStyle()
                .padding(.horizontal, 24)
            } else if !appState.dailyNourishment.isEmpty {
                recipeListCard(appState.dailyNourishment)
            } else if !aiEnabled {
                recipeListCard(defaultRecipes[phase.name] ?? [])
            }
        }
    }

    private func recipeListCard(_ recipes: [Recipe]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(recipes.enumerated()), id: \.element.id) { i, recipe in
                NourishmentListRow(recipe: recipe, currentPhase: phase.name)
                if i < recipes.count - 1 {
                    Divider()
                        .background(Color.lRule)
                        .padding(.leading, 76)
                }
            }
        }
        .background(Color.lPaper)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(Color.lRule, lineWidth: 1))
        .padding(.horizontal, 24)
    }

    // MARK: - Tab bar
    var tabBar: some View {
        HStack(spacing: 0) {
            tabBarItem(icon: "sun.horizon", label: "TODAY", active: true) {}
            tabBarItem(icon: "bookmark", label: "SAVED", active: false) { showSavedRecipes = true }
            tabBarItem(icon: "person", label: "YOU", active: false) { showSettings = true }
        }
        .background(Color.lCream.overlay(
            Rectangle().fill(Color.lRule.opacity(0.5)).frame(height: 0.5), alignment: .top))
    }

    private func tabBarItem(icon: String, label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: active ? .light : .ultraLight))
                    .foregroundColor(active ? .lInk : .lInk3)
                Text(label)
                    .font(LFont.mono(9))
                    .tracking(1.2)
                    .foregroundColor(active ? .lInk : .lInk3)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers
    private func moodSubtext(_ mood: String) -> String {
        switch mood {
        case "Bloated":  return "Lighter today — fennel and ginger."
        case "Tired":    return "Iron and slow carbs to carry you through."
        case "Tender":   return "Warming and easy on the system."
        case "Steady":   return "On course — staying \(phase.name.lowercased())-aligned."
        case "Bright":   return "Riding the wave beautifully."
        default:         return ""
        }
    }

}

// MARK: - Tell Ona sheet
struct TellOnaSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack(alignment: .top) {
            Color.lCream.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: 80)
                    CraveSearchSection(embedded: true)
                }
                .padding(.horizontal, 24)
            }
            HStack {
                Text("Ask Ona")
                    .font(LFont.display(22))
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
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .background(Color.lCream)
        }
        .presentationBackground(Color.lCream)
    }
}

// MARK: - Nourishment list row (in composed recipe card)
struct NourishmentListRow: View {
    let recipe: Recipe
    let currentPhase: String
    @EnvironmentObject var appState: AppState
    @State private var showDetail = false

    var iconColor: Color {
        switch recipe.icon {
        case "salmon": return .lTerracottaDeep
        case "leaf":   return .lSage
        default:       return .lTerracotta
        }
    }

    var body: some View {
        Button { showDetail = true } label: {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.lCream)
                        .frame(width: 44, height: 44)
                        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.lRule, lineWidth: 1))
                    FoodIconView(kind: recipe.icon, size: 28, color: iconColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Eyebrow(recipe.time.uppercased())
                    Text(recipe.name)
                        .font(LFont.displayRegular(19))
                        .foregroundColor(.lInk)
                        .lineSpacing(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(recipe.why)
                        .font(LFont.body(12.5))
                        .foregroundColor(.lInk2)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showDetail) {
            RecipeDetailView(recipe: recipe, currentPhase: currentPhase)
                .environmentObject(appState)
        }
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
                .frame(height: 48)
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

// MARK: - Nourishment card (tappable row → RecipeDetailView)
struct NourishmentCard: View {
    let recipe: Recipe
    let currentPhase: String
    @EnvironmentObject var appState: AppState
    @State private var showDetail = false

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
        Button { showDetail = true } label: {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.lCream)
                        .frame(width: 52, height: 52)
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.lRule, lineWidth: 1))
                    FoodIconView(kind: recipe.icon, size: 34, color: iconColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Eyebrow(recipe.time)
                    Text(recipe.name)
                        .font(LFont.displayRegular(17))
                        .foregroundColor(.lInk)
                        .lineSpacing(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                HStack(spacing: 12) {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(isSaved ? .lPlum : .lInk3)
                        .animation(.easeInOut(duration: 0.15), value: isSaved)
                        .onTapGesture {
                            if isSaved {
                                appState.savedRecipes.removeAll { $0.name == recipe.name }
                            } else {
                                var r = recipe
                                r.phase = currentPhase
                                appState.savedRecipes.append(r)
                            }
                        }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.lInk3)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showDetail) {
            RecipeDetailView(recipe: recipe, currentPhase: currentPhase)
                .environmentObject(appState)
        }
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

                    ShareLink(item: recipeShareText(recipe)) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 13, weight: .regular))
                            Text("Share recipe")
                                .font(LFont.body(13))
                        }
                        .foregroundColor(.lInk2)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.lPaper)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.lRule, lineWidth: 1))
                    }

                    Spacer().frame(height: 10)

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
                .padding(.horizontal, 24)
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
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .background(Color.lCream)
        }
        .presentationBackground(Color.lCream)
    }
}

// MARK: - Saved recipes library sheet
struct SavedRecipesLibrarySheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRecipe: Recipe? = nil

    private let phaseOrder = ["Menstrual", "Follicular", "Ovulatory", "Luteal"]

    private var groupedRecipes: [(phase: String, recipes: [Recipe])] {
        phaseOrder.compactMap { phase in
            let recipes = appState.savedRecipes.filter { $0.phase == phase }
            return recipes.isEmpty ? nil : (phase: phase, recipes: recipes)
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.lCream.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: 80)

                    if appState.savedRecipes.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("No saved recipes yet.")
                                .font(LFont.display(22))
                                .foregroundColor(.lInk)
                            BodyText(text: "Bookmark recipes from your daily nourishment or the Craving Something search and they'll appear here.", size: 14)
                        }
                        .padding(.top, 40)
                    } else {
                        ForEach(groupedRecipes, id: \.phase) { group in
                            Eyebrow(group.phase)
                            Spacer().frame(height: 12)

                            VStack(spacing: 0) {
                                ForEach(group.recipes) { recipe in
                                    Button { selectedRecipe = recipe } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(recipe.name)
                                                    .font(LFont.displayRegular(17))
                                                    .foregroundColor(.lInk)
                                                    .multilineTextAlignment(.leading)
                                                Text(recipe.time)
                                                    .font(LFont.body(12))
                                                    .foregroundColor(.lInk3)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 11))
                                                .foregroundColor(.lInk3)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                    }
                                    .buttonStyle(.plain)

                                    if recipe.id != group.recipes.last?.id {
                                        Divider()
                                            .background(Color.lRule)
                                            .padding(.leading, 16)
                                    }
                                }
                            }
                            .background(Color.lPaper)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.lRule, lineWidth: 1))

                            Spacer().frame(height: 28)
                        }
                    }

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 24)
            }

            HStack {
                Text("Saved")
                    .font(LFont.display(22))
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
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .background(Color.lCream)
        }
        .sheet(item: $selectedRecipe) { recipe in
            SavedRecipeSheet(recipe: recipe)
                .environmentObject(appState)
        }
        .presentationBackground(Color.lCream)
    }
}

// MARK: - Recipe share text
func recipeShareText(_ recipe: Recipe) -> String {
    var lines: [String] = []
    lines.append(recipe.name)
    if !recipe.time.isEmpty { lines.append(recipe.time) }
    if !recipe.why.isEmpty { lines.append("\n\(recipe.why)") }
    if !recipe.ingredients.isEmpty {
        lines.append("\nIngredients:")
        lines.append(contentsOf: recipe.ingredients.map { "• \($0)" })
    }
    if !recipe.steps.isEmpty {
        lines.append("\nSteps:")
        lines.append(contentsOf: recipe.steps.enumerated().map { "\($0.offset + 1). \($0.element)" })
    }
    lines.append("\n— Shared from Ona")
    return lines.joined(separator: "\n")
}

// MARK: - Four-phase progress strip (proportional, full-width)
struct FourPhaseStrip: View {
    let currentDay: Int
    let cycleLength: Int

    private struct Segment {
        let start: Int
        let end: Int
        var days: Int { end - start + 1 }
    }

    private var segments: [Segment] {
        [
            Segment(start: 1,  end: 5),
            Segment(start: 6,  end: 13),
            Segment(start: 14, end: 16),
            Segment(start: 17, end: max(17, cycleLength)),
        ]
    }

    private func isActive(_ s: Segment) -> Bool {
        currentDay >= s.start && currentDay <= s.end
    }

    private func progress(_ s: Segment) -> Double {
        guard isActive(s) else { return 0 }
        let span = Double(s.days)
        guard span > 0 else { return 1 }
        return Double(currentDay - s.start + 1) / span
    }

    var body: some View {
        let spacing: CGFloat = 4
        let totalSpacing = spacing * CGFloat(segments.count - 1)
        let totalDays = Double(max(1, cycleLength))

        GeometryReader { geo in
            let availableWidth = geo.size.width - totalSpacing
            HStack(spacing: spacing) {
                ForEach(segments.indices, id: \.self) { i in
                    let s = segments[i]
                    let segWidth = CGFloat(Double(s.days) / totalDays) * availableWidth
                    let active = isActive(s)
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.lInk.opacity(0.12))
                        if active {
                            Capsule()
                                .fill(Color.lPlum)
                                .frame(width: max(6, segWidth * CGFloat(progress(s))))
                        }
                    }
                    .frame(width: segWidth, height: 6)
                    .animation(.easeInOut(duration: 0.4), value: active)
                }
            }
        }
        .frame(height: 6)
    }
}

// MARK: - Cycle strip
struct CycleStripView: View {
    let day: Int
    let length: Int

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
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
                            } else {
                                Color.clear.frame(width: 4, height: 4)
                            }
                        }
                        .id(d)
                    }
                }
                .padding(.vertical, 4)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .onAppear {
                proxy.scrollTo(day, anchor: .center)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
