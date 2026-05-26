import SwiftUI

enum NourishmentTab { case daily, crave }

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
    @State private var showSavedRecipes = false
    @State private var nourishmentTab: NourishmentTab = .daily

    private var hasProxy: Bool {
        !ProxyConfig.proxyURL.contains("your-subdomain")
    }
    private var hasAPIKey: Bool {
        !(UserDefaults.standard.string(forKey: "anthropicAPIKey") ?? "").isEmpty
    }
    private var aiEnabled: Bool { hasProxy || hasAPIKey }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                profileHeader
                phaseBar
                phaseCard
                divider(32)
                moodCheckIn
                divider(32)
                nourishmentSection
                divider(32)
                partnerShare
                divider(24)
                footer
                Spacer().frame(height: 60)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.lCream.ignoresSafeArea())
        .onAppear {
            refreshIfNeeded()
            if appState.dailyLog.mood != nil && appState.dailyNourishment.isEmpty {
                Task { await appState.loadDailyNourishment() }
            }
        }
        .sheet(isPresented: $showSavedRecipes) {
            SavedRecipesLibrarySheet()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showSettings) {
            SettingsScreen()
                .environmentObject(appState)
        }
    }

    // MARK: - Profile header row (above moon strip)
    var profileHeader: some View {
        HStack {
            Spacer()
            Button { showSettings = true } label: {
                Text(appState.profile.name.prefix(1).uppercased())
                    .font(LFont.display(15))
                    .foregroundColor(phaseColor)
                    .frame(width: 32, height: 32)
                    .background(phaseColor.opacity(0.12))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(phaseColor.opacity(0.3), lineWidth: 1))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 56)
        .padding(.bottom, 10)
    }

    // MARK: - Phase bar (moon + phase name + strip)
    var phaseBar: some View {
        HStack(alignment: .center, spacing: 14) {
            MoonView(
                phase: phase.phase,
                size: 56,
                litColor: .lInk,
                darkColor: Color(red: 42/255, green: 37/255, blue: 32/255).opacity(0.07),
                showCraters: true,
                showGlow: false,
                craterColor: Color(red: 245/255, green: 240/255, blue: 232/255).opacity(0.3)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(phase.name)
                    .font(LFont.display(22))
                    .foregroundColor(.lInk)

                Text("Day \(appState.cycleDay) of \(appState.cycleLength)")
                    .font(LFont.mono(11))
                    .tracking(0.8)
                    .foregroundColor(.lInk3)

                Spacer().frame(height: 5)

                FourPhaseStrip(currentDay: appState.cycleDay, cycleLength: appState.cycleLength)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    // MARK: - Phase explainer card (always open)
    var phaseCard: some View {
        let explainer = phaseExplainer[phase.name] ?? ""
        let foods = phaseFoods[phase.name] ?? []

        return VStack(alignment: .leading, spacing: 0) {
            Text("Why this phase matters")
                .font(LFont.body(12, weight: .medium))
                .foregroundColor(phaseColor)
                .textCase(.uppercase)
                .tracking(0.8)

            Spacer().frame(height: 8)

            Text(explainer)
                .font(LFont.body(14))
                .foregroundColor(.lInk)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer().frame(height: 14)
            Divider().background(Color.lRule)
            Spacer().frame(height: 14)

            FlowLayout(spacing: 6) {
                ForEach(foods, id: \.self) { food in
                    TagChip(label: food, background: phaseColor.opacity(0.12))
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .background(phaseColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, 24)
    }

    // MARK: - Mood check-in
    var moodCheckIn: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("Today's check-in")
            Spacer().frame(height: 10)
            SectionHeader(title: appState.profile.name.isEmpty ? "How are you feeling?" : "\(appState.profile.name), how are you feeling?")

            HStack(spacing: 8) {
                ForEach(["Steady", "Tender", "Tired", "Bright", "Bloated"], id: \.self) { m in
                    MoodOptionButton(label: m, selected: appState.dailyLog.mood == m) {
                        let wasNil = appState.dailyLog.mood == nil
                        appState.dailyLog.mood = appState.dailyLog.mood == m ? nil : m
                        if wasNil, appState.dailyLog.mood != nil {
                            Task { await appState.loadDailyNourishment() }
                        }
                    }
                }
            }

            if let mood = appState.dailyLog.mood {
                HStack {
                    Text(moodResponse(mood))
                        .font(LFont.body(13))
                        .foregroundColor(phaseColor)
                        .lineSpacing(3)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(phaseColor.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(phaseColor.opacity(0.2), lineWidth: 1))
                .padding(.top, 14)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 24)
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
            // Eyebrow + bookmark
            HStack(alignment: .center) {
                Eyebrow("Nourishment")
                Spacer()
                Button { showSavedRecipes = true } label: {
                    Image(systemName: appState.savedRecipes.isEmpty ? "bookmark" : "bookmark.fill")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(appState.savedRecipes.isEmpty ? .lInk2 : .lPlum)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 10)

            // Display-size tab headers
            if aiEnabled {
                HStack(alignment: .bottom, spacing: 24) {
                    tabHeader("Today's meals", tab: .daily)
                    tabHeader("Craving something?", tab: .crave)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            } else {
                Text("Today's meals")
                    .font(LFont.display(22))
                    .foregroundColor(.lInk)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
            }

            // Tab content
            if nourishmentTab == .daily {
                if appState.nourishmentLoading && appState.dailyNourishment.isEmpty {
                    HStack(spacing: 12) {
                        SpinnerView()
                        Text("Preparing today's meals…")
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
                        Text("Couldn't load meals")
                            .font(LFont.body(13, weight: .medium))
                            .foregroundColor(.lRed)
                        Text(err)
                            .font(LFont.body(12))
                            .foregroundColor(.lRed.opacity(0.7))
                            .lineSpacing(2)
                        Button {
                            appState.nourishmentError = nil
                            Task { await appState.loadDailyNourishment() }
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
                } else if appState.dailyNourishment.isEmpty {
                    Text("Check in above and Ona will build your meals for the day.")
                        .font(LFont.body(14))
                        .foregroundColor(.lInk3)
                        .lineSpacing(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .cardStyle()
                        .padding(.horizontal, 24)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 12) {
                            ForEach(appState.dailyNourishment) { recipe in
                                NourishmentCard(recipe: recipe, currentPhase: phase.name)
                                    .frame(width: 300)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 2)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                CraveSearchSection(embedded: true)
                    .padding(.horizontal, 24)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: nourishmentTab)
    }

    private func tabHeader(_ label: String, tab: NourishmentTab) -> some View {
        let active = nourishmentTab == tab
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { nourishmentTab = tab }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(LFont.display(22))
                    .foregroundColor(active ? .lInk : .lInk3)
                Rectangle()
                    .fill(active ? phaseColor : Color.clear)
                    .frame(height: 2)
                    .clipShape(Capsule())
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: active)
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
        .padding(.horizontal, 24)
    }

    // MARK: - Footer
    var footer: some View {
        Eyebrow("Ona · cycle nutrition, shaped for her", color: .lInk3)
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
            if !expanded { Spacer(minLength: 0) }
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
            .background(
                Color.lCream
                    .ignoresSafeArea(edges: .top)
                    .shadow(color: Color.lInk.opacity(0.04), radius: 8, x: 0, y: 4)
            )
        }
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
            .background(
                Color.lCream
                    .ignoresSafeArea(edges: .top)
                    .shadow(color: Color.lInk.opacity(0.04), radius: 8, x: 0, y: 4)
            )
        }
        .sheet(item: $selectedRecipe) { recipe in
            SavedRecipeSheet(recipe: recipe)
                .environmentObject(appState)
        }
    }
}

// MARK: - Four-phase progress strip
struct FourPhaseStrip: View {
    let currentDay: Int
    let cycleLength: Int

    private struct Segment {
        let start: Int
        let end: Int
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
        let span = Double(s.end - s.start)
        guard span > 0 else { return 1 }
        return Double(currentDay - s.start) / span
    }

    var body: some View {
        HStack(spacing: 5) {
            ForEach(segments.indices, id: \.self) { i in
                let s = segments[i]
                let active = isActive(s)
                let pillWidth: CGFloat = active ? 48 : 8
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.lInk.opacity(0.12))
                        .frame(width: pillWidth, height: 6)
                    if active {
                        Capsule()
                            .fill(Color.lInk)
                            .frame(width: max(6, pillWidth * progress(s)), height: 6)
                    }
                }
                .animation(.easeInOut(duration: 0.4), value: active)
            }
        }
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
