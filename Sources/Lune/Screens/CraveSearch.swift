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
    let summary: String?
    let recipes: [GeneratedRecipeData]
}

struct OnaResponse: Codable {
    let type: String
    let answer: String?
    let recipes: [GeneratedRecipeData]?
}

enum OnaResult {
    case answer(String)
    case recipes([GeneratedRecipeData])
}

private let phaseCravingSuggestions: [String: [String]] = [
    "Menstrual":  [
        "help with cramps",
        "quick breakfast with dark chocolate",
        "something sweet but nourishing",
    ],
    "Follicular": [
        "light lunch to boost energy",
        "help with skin glow",
        "quick high-protein meal",
    ],
    "Ovulatory":  [
        "vibrant salad ideas",
        "snack before a workout",
        "something with avocado",
    ],
    "Luteal":     [
        "midday snack with dates",
        "help reduce bloating",
        "something with dark chocolate",
    ],
]

struct CraveSearchSection: View {
    @EnvironmentObject var appState: AppState
    var embedded: Bool = false
    @State private var query = ""
    @State private var loading = false
    @State private var result: OnaResult? = nil
    @State private var error: String? = nil
    @State private var submittedFor = ""
    @State private var expandedIndex: Int? = 0
    @FocusState private var isFocused: Bool

    private var phase: CyclePhaseInfo { appState.phaseInfo }
    private var isExpanded: Bool { isFocused || !query.isEmpty || result != nil || loading }
    private var suggestions: [String] { phaseCravingSuggestions[phase.name] ?? [] }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Card
            VStack(alignment: .leading, spacing: 0) {

                // Search bar row
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13))
                        .foregroundColor(.lInk3)

                    TextField("an ingredient, a craving…", text: $query)
                        .font(LFont.body(14))
                        .foregroundColor(.lInk)
                        .focused($isFocused)
                        .onSubmit { Task { await generate() } }

                    Button {
                        Task { await generate() }
                    } label: {
                        Text(loading ? "…" : "Go")
                            .font(LFont.body(13, weight: .medium))
                            .foregroundColor(canSubmit ? .lCream : .lInk3)
                            .padding(.horizontal, 14)
                            .frame(height: 34)
                            .background(canSubmit ? Color.lPlum : Color.lCream2)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .disabled(!canSubmit)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 4)
                .background(Color.lCream2.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isFocused ? Color.lPlum.opacity(0.4) : Color.lRule, lineWidth: 1))

                if result == nil && !loading {
                    Spacer().frame(height: 10)
                    Text("Ask a food question or share what you're craving.")
                        .font(LFont.body(12))
                        .foregroundColor(.lInk2)
                    Spacer().frame(height: 4)
                    Text("Tuned to your \(phase.name.lowercased()) phase\(appState.dailyLog.mood.map { " and feeling \($0.lowercased())" } ?? "").")
                        .font(LFont.body(12))
                        .foregroundColor(.lInk3)

                    Spacer().frame(height: 14)
                    FlowLayout(spacing: 6) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button {
                                query = suggestion
                                Task { await generate() }
                            } label: {
                                Text(suggestion)
                                    .font(LFont.body(12))
                                    .foregroundColor(.lInk2)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(Color.lCream)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(Color.lRule, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
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
                if let r = result {
                    VStack(alignment: .leading, spacing: 10) {
                        Eyebrow("For \"\(submittedFor)\" · \(phase.name.lowercased())", color: .lSageDeep)
                            .padding(.top, 14)

                        switch r {
                        case .answer(let text):
                            Text(text)
                                .font(LFont.body(14))
                                .foregroundColor(.lInk)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)

                            ShareLink(item: text) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.lInk2)
                                    .frame(width: 38, height: 38)
                                    .background(Color.lCream2)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color.lRule, lineWidth: 1))
                            }

                        case .recipes(let recipes):
                            ForEach(recipes.indices, id: \.self) { i in
                                GeneratedRecipeCard(
                                    recipe: recipes[i],
                                    currentPhase: phase.name,
                                    open: expandedIndex == i
                                ) {
                                    withAnimation(.easeInOut(duration: 0.22)) {
                                        expandedIndex = expandedIndex == i ? nil : i
                                    }
                                }
                            }
                        }

                        Button {
                            withAnimation {
                                result = nil
                                query = ""
                                submittedFor = ""
                                isFocused = false
                            }
                        } label: {
                            Text("← ask something else")
                                .font(LFont.body(12.5))
                                .foregroundColor(.lInk3)
                        }
                        .padding(.top, 2)
                    }
                    .transition(.opacity)
                }
            }
            .padding(16)
            .background(Color.lPaper)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.lRule, lineWidth: 1))
        }
        .padding(.horizontal, embedded ? 0 : 24)
        .animation(.easeInOut(duration: 0.2), value: loading)
        .animation(.easeInOut(duration: 0.2), value: result == nil)
    }

    private var canSubmit: Bool { !query.trimmingCharacters(in: .whitespaces).isEmpty && !loading }

    @MainActor
    private func generate() async {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty, !loading else { return }

        loading = true
        error = nil
        result = nil
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
        let season = appState.currentSeason()

        let prompt = """
        You are Ona, a warm and knowledgeable nutritionist who understands the menstrual cycle deeply.

        Today's context:
        - Cycle phase: \(phase.name)
        - Season: \(season) — favour ingredients that are naturally in season
        - How she feels today: \(mood)
        - Symptoms she wants to address: \(symptoms)
        - Dietary preferences: \(diet)
        - Cooking style & flavour profile: \(cookingStyles)\(cookingStyleNotes.isEmpty ? "" : ". Additional: \(cookingStyleNotes)")
        - Her message: \(q)

        First decide: is this a question about food, nutrition, or her cycle? Or is it a request for recipe ideas?

        If it is a QUESTION, respond with a warm, specific answer (2–4 sentences) grounded in her current phase and how she feels.
        If it is a RECIPE REQUEST, suggest TWO simple recipes (30 min or less) suited to her \(phase.name) phase.

        Respond with ONLY a valid JSON object — no prose, no markdown, no code fences.

        For a question:
        { "type": "answer", "answer": "your response here" }

        For recipes:
        {
          "type": "recipes",
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

            let decoded = try JSONDecoder().decode(OnaResponse.self, from: Data(cleaned.utf8))
            switch decoded.type {
            case "answer":
                guard let ans = decoded.answer, !ans.isEmpty else { throw URLError(.badServerResponse) }
                result = .answer(ans)
            case "recipes":
                guard let r = decoded.recipes, !r.isEmpty else { throw URLError(.badServerResponse) }
                result = .recipes(r)
            default:
                throw URLError(.badServerResponse)
            }
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
    @State private var tweakedRecipe: GeneratedRecipeData? = nil
    @State private var tweaking = false
    @State private var tweakText = ""
    @State private var tweakLoading = false

    var display: GeneratedRecipeData { tweakedRecipe ?? recipe }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row (always visible)
            Button(action: onToggle) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Eyebrow(display.time, color: .lInk3)
                        Text(display.name)
                            .font(LFont.displayRegular(18))
                            .foregroundColor(.lInk)
                        BodyText(text: display.why, size: 12.5)
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

                        ForEach(display.ingredients.indices, id: \.self) { i in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(Color.lTerracotta)
                                    .frame(width: 4, height: 4)
                                    .padding(.top, 8)
                                Text(display.ingredients[i])
                                    .font(LFont.body(13))
                                    .foregroundColor(.lInk2)
                                    .lineSpacing(2)
                            }
                            .padding(.bottom, 5)
                        }

                        if !display.steps.isEmpty {
                            Spacer().frame(height: 14)
                            Eyebrow("Prep", color: .lInk3)
                            Spacer().frame(height: 8)

                            ForEach(display.steps.indices, id: \.self) { i in
                                HStack(alignment: .top, spacing: 10) {
                                    Text(String(format: "%02d", i + 1))
                                        .font(LFont.mono(10))
                                        .tracking(1)
                                        .foregroundColor(.lInk3)
                                        .padding(.top, 3)
                                    Text(display.steps[i])
                                        .font(LFont.body(13))
                                        .foregroundColor(.lInk2)
                                        .lineSpacing(2)
                                }
                                .padding(.bottom, 6)
                            }
                        }

                        Spacer().frame(height: 14)

                        HStack(spacing: 8) {
                            Button {
                                if !isSaved {
                                    let r = Recipe(
                                        name: display.name,
                                        time: display.time,
                                        why: display.why,
                                        ingredients: display.ingredients,
                                        steps: display.steps,
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

                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    tweaking.toggle()
                                    if !tweaking { tweakText = "" }
                                }
                            } label: {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(tweaking ? .lPlum : .lInk2)
                                    .frame(width: 38, height: 38)
                                    .background(tweaking ? Color.lPlum.opacity(0.1) : Color.lCream2)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(tweaking ? Color.lPlum.opacity(0.3) : Color.lRule, lineWidth: 1))
                            }

                            ShareLink(item: generatedRecipeShareText(display)) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.lInk2)
                                    .frame(width: 38, height: 38)
                                    .background(Color.lCream2)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color.lRule, lineWidth: 1))
                            }
                        }

                        if tweaking {
                            Spacer().frame(height: 10)
                            HStack(spacing: 8) {
                                TextField("e.g. use whole milk, swap walnuts…", text: $tweakText)
                                    .font(LFont.body(13))
                                    .foregroundColor(.lInk)
                                    .autocorrectionDisabled()
                                    .onSubmit { Task { await performTweak() } }
                                Button {
                                    Task { await performTweak() }
                                } label: {
                                    Text(tweakLoading ? "…" : "Go")
                                        .font(LFont.body(13, weight: .medium))
                                        .foregroundColor(tweakText.trimmingCharacters(in: .whitespaces).isEmpty ? .lInk3 : .lCream)
                                        .padding(.horizontal, 14)
                                        .frame(height: 34)
                                        .background(tweakText.trimmingCharacters(in: .whitespaces).isEmpty ? Color.lCream2 : Color.lPlum)
                                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                                }
                                .disabled(tweakText.trimmingCharacters(in: .whitespaces).isEmpty || tweakLoading)
                            }
                            .padding(10)
                            .background(Color.lInk.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
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

    @MainActor
    private func performTweak() async {
        let t = tweakText.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        tweakLoading = true
        do {
            let d = display
            let result = try await callAnthropicTweak(
                name: d.name, time: d.time, why: d.why,
                ingredients: d.ingredients, steps: d.steps,
                tweak: t,
                phase: currentPhase,
                season: appState.currentSeason(),
                diet: appState.profile.diet.isEmpty ? "no restrictions" : appState.profile.diet.joined(separator: ", ")
            )
            tweakedRecipe = result
            isSaved = false
            withAnimation(.easeInOut(duration: 0.2)) {
                tweaking = false
                tweakText = ""
            }
        } catch { }
        tweakLoading = false
    }
}

// MARK: - Share text helper
func generatedRecipeShareText(_ recipe: GeneratedRecipeData) -> String {
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

// MARK: - Recipe tweak call
func callAnthropicTweak(
    name: String, time: String, why: String,
    ingredients: [String], steps: [String],
    tweak: String, phase: String, season: String, diet: String
) async throws -> GeneratedRecipeData {
    let prompt = """
    You are a warm, knowledgeable nutritionist.

    Adjust this recipe based on the following request: \(tweak)
    Keep the same dish concept and meal timing. Only change what was asked.

    Original:
    Name: \(name)
    Ingredients: \(ingredients.joined(separator: " · "))

    Context:
    - Cycle phase: \(phase)
    - Season: \(season)
    - Dietary preferences: \(diet)

    Respond with ONLY a valid JSON object — no prose, no markdown, no code fences:
    {
      "name": "short evocative name (max 6 words)",
      "time": "\(time)",
      "why": "ONE warm sentence (max 18 words) tying it to the \(phase) phase",
      "ingredients": ["7-9 short ingredient lines with quantities"],
      "steps": ["3-5 brief prep steps, one sentence each"]
    }
    """
    let text = try await callAnthropic(prompt: prompt)
    let cleaned = text
        .replacingOccurrences(of: "^```(?:json)?\\s*", with: "", options: .regularExpression)
        .replacingOccurrences(of: "```\\s*$", with: "", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
    return try JSONDecoder().decode(GeneratedRecipeData.self, from: Data(cleaned.utf8))
}

// MARK: - Anthropic API call (shared with AppState for daily nourishment)
func callAnthropic(prompt: String) async throws -> String {
    let proxyConfigured = !ProxyConfig.proxyURL.contains("your-subdomain")

    // Try proxy; if it fails or isn't configured, fall back to direct key
    if proxyConfigured {
        do {
            return try await callAnthropicViaProxy(prompt: prompt)
        } catch {
            // Proxy failed — fall through to direct key
        }
    }
    return try await callAnthropicDirect(prompt: prompt)
}

private func callAnthropicViaProxy(prompt: String) async throws -> String {
    guard let url = URL(string: ProxyConfig.proxyURL) else { throw URLError(.badURL) }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    if !ProxyConfig.proxySecret.isEmpty {
        request.setValue(ProxyConfig.proxySecret, forHTTPHeaderField: "X-Ona-Secret")
    }
    request.httpBody = try JSONSerialization.data(withJSONObject: ["prompt": prompt])

    let (data, response) = try await URLSession.shared.data(for: request)
    if let http = response as? HTTPURLResponse, http.statusCode != 200 {
        let detail = String(data: data, encoding: .utf8) ?? ""
        throw NSError(domain: "Ona", code: http.statusCode,
                      userInfo: [NSLocalizedDescriptionKey: "Proxy error \(http.statusCode): \(detail)"])
    }
    struct Resp: Decodable { let text: String }
    let resp = try JSONDecoder().decode(Resp.self, from: data)
    return resp.text
}

private func callAnthropicDirect(prompt: String) async throws -> String {
    let apiKey = UserDefaults.standard.string(forKey: "anthropicAPIKey")
        ?? ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]
        ?? ""
    guard !apiKey.isEmpty else {
        throw NSError(domain: "Ona", code: 0,
                      userInfo: [NSLocalizedDescriptionKey: "No API key — add one in Settings or check the proxy setup."])
    }

    var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
    request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

    let body: [String: Any] = [
        "model": "claude-haiku-4-5-20251001",
        "max_tokens": 4096,
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
