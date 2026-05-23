import SwiftUI

// MARK: - AI Recipe Generator
// Calls the Anthropic Messages API to generate two phase-tuned recipes.
// Set ANTHROPIC_API_KEY in the scheme environment, or hardcode for dev only.

struct GeneratedRecipeData: Codable {
    let name: String
    let time: String
    let why: String
    let ingredients: [String]
    let steps: [String]
}

struct RecipeResponse: Codable {
    let recipes: [GeneratedRecipeData]
}

struct CraveSearchSection: View {
    @EnvironmentObject var appState: AppState
    @State private var query = ""
    @State private var loading = false
    @State private var recipes: [GeneratedRecipeData]? = nil
    @State private var error: String? = nil
    @State private var submittedFor = ""
    @State private var expandedIndex: Int? = 0
    @FocusState private var isFocused: Bool

    private let ideas = ["beets", "dark chocolate", "sweet potato", "salmon", "ginger"]
    private var phase: CyclePhaseInfo { appState.phaseInfo }
    private var isExpanded: Bool { isFocused || !query.isEmpty || recipes != nil || loading }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Persistent search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13))
                    .foregroundColor(.lInk3)

                TextField("Craving something? Tell Ona…", text: $query)
                    .font(LFont.body(14))
                    .foregroundColor(.lInk)
                    .focused($isFocused)
                    .onSubmit { Task { await generate() } }

                if isExpanded {
                    Button {
                        Task { await generate() }
                    } label: {
                        Text(loading ? "..." : "Suggest")
                            .font(LFont.body(13, weight: .medium))
                            .foregroundColor(canSubmit ? .lCream : .lInk3)
                            .padding(.horizontal, 14)
                            .frame(height: 34)
                            .background(canSubmit ? Color.lPlum : Color.lCream2)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .disabled(!canSubmit)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .padding(.leading, 14)
            .padding(.trailing, isExpanded ? 4 : 14)
            .padding(.vertical, isExpanded ? 4 : 10)
            .background(Color.lPaper)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isFocused ? Color.lPlum.opacity(0.4) : Color.lRule, lineWidth: 1))
            .animation(.easeInOut(duration: 0.18), value: isExpanded)

            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {

                    // Idea chips + footnote
                    if recipes == nil && !loading {
                        Spacer().frame(height: 14)
                        FlowLayout(spacing: 6) {
                            ForEach(ideas, id: \.self) { idea in
                                Button { query = idea } label: {
                                    Text(idea)
                                        .font(LFont.body(12))
                                        .foregroundColor(.lInk2)
                                        .padding(.horizontal, 11)
                                        .padding(.vertical, 5)
                                        .background(Color.clear)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(Color.lRule, lineWidth: 1))
                                }
                            }
                        }
                        Text("Tuned to your \(phase.name.lowercased()) phase\(appState.dailyLog.mood.map { ", feeling \($0.lowercased())" } ?? "").")
                            .font(LFont.body(11.5))
                            .foregroundColor(.lInk3)
                            .padding(.top, 8)
                    }

                    // Loading
                    if loading {
                        HStack(spacing: 10) {
                            SpinnerView()
                            Text("Cooking up ideas with \(submittedFor)…")
                                .font(LFont.body(13))
                                .italic()
                                .foregroundColor(.lInk2)
                        }
                        .padding(.top, 14)
                        .transition(.opacity)
                    }

                    // Error
                    if let err = error {
                        Text(err)
                            .font(LFont.body(12.5))
                            .foregroundColor(.lRed)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(hex: "9a4a3e").opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .padding(.top, 14)
                            .transition(.opacity)
                    }

                    // Results
                    if let r = recipes {
                        VStack(alignment: .leading, spacing: 10) {
                            Eyebrow("For \"\(submittedFor)\" · \(phase.name.lowercased())", color: .lSageDeep)
                                .padding(.top, 14)
                            ForEach(r.indices, id: \.self) { i in
                                GeneratedRecipeCard(
                                    recipe: r[i],
                                    currentPhase: phase.name,
                                    open: expandedIndex == i
                                ) {
                                    withAnimation(.easeInOut(duration: 0.22)) {
                                        expandedIndex = expandedIndex == i ? nil : i
                                    }
                                }
                            }
                            Button {
                                withAnimation {
                                    recipes = nil
                                    query = ""
                                    submittedFor = ""
                                    isFocused = false
                                }
                            } label: {
                                Text("← try another")
                                    .font(LFont.body(12.5))
                                    .foregroundColor(.lInk3)
                            }
                            .padding(.top, 2)
                        }
                        .transition(.opacity)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
        .animation(.easeInOut(duration: 0.2), value: loading)
        .animation(.easeInOut(duration: 0.2), value: recipes == nil)
    }

    private var canSubmit: Bool { !query.trimmingCharacters(in: .whitespaces).isEmpty && !loading }

    @MainActor
    private func generate() async {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty, !loading else { return }

        loading = true
        error = nil
        recipes = nil
        submittedFor = q
        expandedIndex = 0

        let symptoms = appState.profile.symptoms.isEmpty
            ? "none specified"
            : appState.profile.symptoms.joined(separator: ", ")
        let diet = appState.profile.diet.isEmpty
            ? "no restrictions"
            : appState.profile.diet.joined(separator: ", ")
        let cookingStyles = appState.profile.cookingStyles.isEmpty
            ? "no preference"
            : appState.profile.cookingStyles.joined(separator: ", ")
        let cookingStyleNotes = appState.profile.cookingStyleNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        let mood = appState.dailyLog.mood ?? "not logged"
        let notes = appState.profile.notes.trimmingCharacters(in: .whitespacesAndNewlines)

        let prompt = """
        You are a warm, knowledgeable nutritionist who designs recipes around the menstrual cycle.

        Today's context:
        - Cycle phase: \(phase.name)
        - How she feels today: \(mood)
        - Symptoms she wants to address: \(symptoms)
        - Dietary preferences: \(diet)
        - Cooking style & flavour profile: \(cookingStyles)\(cookingStyleNotes.isEmpty ? "" : ". Additional: \(cookingStyleNotes)")
        - Personal notes: \(notes.isEmpty ? "none" : notes)
        - She is craving / wants to use: \(q)

        Suggest TWO simple, real recipes that center "\(q)" and are well-suited to her \(phase.name) phase and how she's feeling. Recipes should be doable in 30 minutes or less.

        Respond with ONLY a valid JSON object — no prose, no markdown, no code fences. Use this exact schema:

        {
          "recipes": [
            {
              "name": "short evocative name (max 6 words)",
              "time": "e.g. 15 min",
              "why": "ONE warm sentence (max 18 words) tying it to her \(phase.name) phase and feelings",
              "ingredients": ["7-9 short ingredient lines with quantities"],
              "steps": ["3-5 brief prep steps, one sentence each"]
            }
          ]
        }
        """

        do {
            let text = try await callAnthropic(prompt: prompt)
            let cleaned = text
                .replacingOccurrences(of: "^```(?:json)?\\s*", with: "", options: .regularExpression)
                .replacingOccurrences(of: "```\\s*$", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let data = try JSONDecoder().decode(RecipeResponse.self, from: Data(cleaned.utf8))
            guard data.recipes.count >= 1 else { throw URLError(.badServerResponse) }
            recipes = data.recipes
        } catch {
            self.error = "Couldn't quite catch that — try again?"
        }

        loading = false
    }
}

// MARK: - Generated recipe card
struct GeneratedRecipeCard: View {
    let recipe: GeneratedRecipeData
    let currentPhase: String
    let open: Bool
    let onToggle: () -> Void
    @EnvironmentObject var appState: AppState
    @State private var isSaved = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row (always visible)
            Button(action: onToggle) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Eyebrow(recipe.time, color: .lInk3)
                        Text(recipe.name)
                            .font(LFont.displayRegular(18))
                            .foregroundColor(.lInk)
                        BodyText(text: recipe.why, size: 12.5)
                    }

                    Spacer(minLength: 8)

                    ZStack {
                        Circle().fill(Color.lCream2).frame(width: 22, height: 22)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9))
                            .foregroundColor(.lInk)
                            .rotationEffect(.degrees(open ? 180 : 0))
                            .animation(.easeInOut(duration: 0.22), value: open)
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            // Expanded content
            if open {
                VStack(alignment: .leading, spacing: 0) {
                    Divider().background(Color.lRule)

                    VStack(alignment: .leading, spacing: 0) {
                        Eyebrow("Ingredients", color: .lInk3)
                        Spacer().frame(height: 8)

                        ForEach(recipe.ingredients.indices, id: \.self) { i in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(Color.lTerracotta)
                                    .frame(width: 4, height: 4)
                                    .padding(.top, 8)
                                Text(recipe.ingredients[i])
                                    .font(LFont.body(13))
                                    .foregroundColor(.lInk2)
                                    .lineSpacing(2)
                            }
                            .padding(.bottom, 5)
                        }

                        if !recipe.steps.isEmpty {
                            Spacer().frame(height: 14)
                            Eyebrow("Prep", color: .lInk3)
                            Spacer().frame(height: 8)

                            ForEach(recipe.steps.indices, id: \.self) { i in
                                HStack(alignment: .top, spacing: 10) {
                                    Text(String(format: "%02d", i + 1))
                                        .font(LFont.mono(10))
                                        .tracking(1)
                                        .foregroundColor(.lInk3)
                                        .padding(.top, 3)
                                    Text(recipe.steps[i])
                                        .font(LFont.body(13))
                                        .foregroundColor(.lInk2)
                                        .lineSpacing(2)
                                }
                                .padding(.bottom, 6)
                            }
                        }

                        Spacer().frame(height: 14)

                        Button {
                            if !isSaved {
                                let r = Recipe(
                                    name: recipe.name,
                                    time: recipe.time,
                                    why: recipe.why,
                                    ingredients: recipe.ingredients,
                                    steps: recipe.steps,
                                    icon: "leaf",
                                    phase: currentPhase
                                )
                                appState.savedRecipes.append(r)
                                isSaved = true
                            }
                        } label: {
                            Text(isSaved ? "Saved ✓" : "Save recipe")
                                .font(LFont.body(13, weight: .medium))
                                .foregroundColor(.lCream)
                                .frame(maxWidth: .infinity)
                                .frame(height: 38)
                                .background(isSaved ? Color.lSageDeep : Color.lPlum)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .animation(.easeInOut(duration: 0.2), value: isSaved)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 18)
                    .padding(.top, 14)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.lCream)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.lRule, lineWidth: 1))
        .clipped()
    }
}

// MARK: - Spinner
struct SpinnerView: View {
    @State private var angle: Double = 0

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.75)
            .stroke(Color.lInk, lineWidth: 2)
            .frame(width: 18, height: 18)
            .rotationEffect(.degrees(angle))
            .onAppear {
                withAnimation(.linear(duration: 0.7).repeatForever(autoreverses: false)) {
                    angle = 360
                }
            }
    }
}

// MARK: - Anthropic API call (shared with AppState for daily nourishment)
func callAnthropic(prompt: String) async throws -> String {
    let apiKey = UserDefaults.standard.string(forKey: "anthropicAPIKey")
        ?? ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]
        ?? ""
    guard !apiKey.isEmpty else {
        throw NSError(domain: "Ona", code: 0,
                      userInfo: [NSLocalizedDescriptionKey: "ANTHROPIC_API_KEY not set"])
    }

    var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
    request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

    let body: [String: Any] = [
        "model": "claude-haiku-4-5-20251001",
        "max_tokens": 1024,
        "messages": [["role": "user", "content": prompt]],
    ]
    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, _) = try await URLSession.shared.data(for: request)

    struct Resp: Decodable {
        struct Content: Decodable { let text: String }
        let content: [Content]
    }
    let resp = try JSONDecoder().decode(Resp.self, from: data)
    guard let text = resp.content.first?.text else { throw URLError(.badServerResponse) }
    return text
}
