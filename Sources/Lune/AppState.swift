import SwiftUI
import Combine

enum AppScreen: String {
    case connect
    case signupSymptoms
    case signupDiet
    case signupCookingStyle
    case signupNotes
    case home
}

@MainActor
class AppState: ObservableObject {
    @Published var screen: AppScreen = .connect

    @Published var profile = Profile()

    @Published var cycleDay: Int = 1
    @Published var cycleLength: Int = 28
    @Published var healthKitLoading: Bool = false
    @Published var healthKitError: String? = nil

    @Published var dailyLog = DailyLog()
    @Published var savedRecipes: [Recipe] = []

    // Daily AI-generated nourishment
    @Published var dailyNourishment: [Recipe] = []
    @Published var nourishmentLoading: Bool = false
    @Published var nourishmentDate: String = ""
    @Published var nourishmentError: String? = nil
    @Published var recentRecipeNames: [String] = []
    @Published var dailySummary: String = ""

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var cancellables = Set<AnyCancellable>()

    init() {
        load()
        objectWillChange
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.save() }
            .store(in: &cancellables)
    }

    var phaseInfo: CyclePhaseInfo {
        cyclePhase(day: cycleDay, length: cycleLength)
    }

    // MARK: - Persistence

    func computeCycleDayFromManual() {
        guard !profile.healthKitConnected else { return }
        let length = max(profile.manualCycleLength, 1)
        cycleLength = length
        guard let refDate = profile.referencePeriodDate else { return }
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let ref = cal.startOfDay(for: refDate)
        let days = cal.dateComponents([.day], from: ref, to: today).day ?? 0
        guard days >= 0 else { return }
        cycleDay = (days % length) + 1
    }

    func setManualCycle(referenceDate: Date, length: Int) {
        profile.referencePeriodDate = referenceDate
        profile.manualCycleLength = length
        computeCycleDayFromManual()
        advance()
    }

    private func load() {
        if let data = defaults.data(forKey: "profile"),
           let p = try? decoder.decode(Profile.self, from: data) {
            profile = p
        }

        if let raw = defaults.string(forKey: "screen"),
           let s = AppScreen(rawValue: raw) {
            screen = s
        }

        let today = todayString()

        // DailyLog resets each calendar day
        if defaults.string(forKey: "dailyLogDate") == today,
           let data = defaults.data(forKey: "dailyLog"),
           let log = try? decoder.decode(DailyLog.self, from: data) {
            dailyLog = log
        }

        if let data = defaults.data(forKey: "savedRecipes"),
           let recipes = try? decoder.decode([Recipe].self, from: data) {
            savedRecipes = recipes
        }

        // Restore today's nourishment if it was already generated today
        if defaults.string(forKey: "nourishmentDate") == today,
           let data = defaults.data(forKey: "dailyNourishment"),
           let recipes = try? decoder.decode([Recipe].self, from: data) {
            dailyNourishment = recipes
            nourishmentDate = today
            dailySummary = defaults.string(forKey: "dailySummary") ?? ""
        }

        if let data = defaults.data(forKey: "recentRecipeNames"),
           let names = try? decoder.decode([String].self, from: data) {
            recentRecipeNames = names
        }

        if profile.referencePeriodDate != nil && !profile.healthKitConnected {
            computeCycleDayFromManual()
        } else {
            let d = defaults.integer(forKey: "cycleDay")
            cycleDay = d > 0 ? d : 1
            let l = defaults.integer(forKey: "cycleLength")
            cycleLength = l > 0 ? l : 28
        }
    }

    private func save() {
        if let data = try? encoder.encode(profile) {
            defaults.set(data, forKey: "profile")
        }
        defaults.set(screen.rawValue, forKey: "screen")
        if let data = try? encoder.encode(dailyLog) {
            defaults.set(data, forKey: "dailyLog")
            defaults.set(todayString(), forKey: "dailyLogDate")
        }
        if let data = try? encoder.encode(savedRecipes) {
            defaults.set(data, forKey: "savedRecipes")
        }
        if let data = try? encoder.encode(dailyNourishment) {
            defaults.set(data, forKey: "dailyNourishment")
            defaults.set(nourishmentDate, forKey: "nourishmentDate")
            defaults.set(dailySummary, forKey: "dailySummary")
        }
        if let data = try? encoder.encode(recentRecipeNames) {
            defaults.set(data, forKey: "recentRecipeNames")
        }
        defaults.set(cycleDay, forKey: "cycleDay")
        defaults.set(cycleLength, forKey: "cycleLength")
    }

    func todayString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    func currentSeason() -> String {
        switch Calendar.current.component(.month, from: Date()) {
        case 3:  return "early spring"
        case 4:  return "mid spring"
        case 5:  return "late spring"
        case 6:  return "early summer"
        case 7:  return "mid summer"
        case 8:  return "late summer"
        case 9:  return "early autumn"
        case 10: return "mid autumn"
        case 11: return "late autumn"
        case 12: return "early winter"
        case 1:  return "mid winter"
        case 2:  return "late winter"
        default: return "spring"
        }
    }

    // MARK: - Daily nourishment generation

    func loadDailyNourishment(craving: String = "") async {
        let today = todayString()
        guard nourishmentDate != today || dailyNourishment.isEmpty else { return }

        nourishmentLoading = true
        nourishmentError = nil

        let phase = phaseInfo
        let symptoms = profile.symptoms.isEmpty ? "none" : profile.symptoms.joined(separator: ", ")
        let diet = profile.diet.isEmpty ? "no restrictions" : profile.diet.joined(separator: ", ")
        let cookingStyles = profile.cookingStyles.isEmpty ? "no preference" : profile.cookingStyles.joined(separator: ", ")
        let cookingStyleNotes = profile.cookingStyleNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        let mood = dailyLog.mood ?? "not logged"
        let season = currentSeason()
        let avoidClause = recentRecipeNames.isEmpty ? "" :
            "\nAvoid repeating these recently served recipes: \(recentRecipeNames.prefix(14).joined(separator: ", "))."
        let cravingClause = craving.trimmingCharacters(in: .whitespaces).isEmpty ? "" :
            "\n- Craving: \"\(craving.trimmingCharacters(in: .whitespaces))\" — work this in where it fits naturally."

        let prompt = """
        You are a warm, knowledgeable nutritionist who designs meals around the menstrual cycle.

        Generate exactly 3 complete recipes for someone in their \(phase.name) phase, day \(cycleDay) of a \(cycleLength)-day cycle.

        Context:
        - Season: \(season) — favour ingredients that are naturally in season
        - Symptoms to address: \(symptoms)
        - Dietary preferences: \(diet)
        - Cooking style & flavour profile: \(cookingStyles)\(cookingStyleNotes.isEmpty ? "" : ". Additional: \(cookingStyleNotes)")
        - How she feels today: \(mood)\(cravingClause)\(avoidClause)

        Each recipe should be doable in 30 minutes or less and specifically suited to the \(phase.name) phase. Vary the meal timing: one morning, one midday, one evening. All ingredient quantities should be calibrated for one serving — main components (grains, protein, veg) in substantive amounts (e.g. 80 g, ½ cup, 1 fillet), supporting ingredients (oils, spices, dressings) in appropriately smaller amounts (1 tbsp, ½ tsp). Avoid listing a bulk quantity of one ingredient alongside trace amounts of everything else.

        Also write a "summary": one warm, italic-ready sentence (max 12 words) describing the overall nutritional approach for today.

        Respond with ONLY a valid JSON object — no prose, no markdown, no code fences:

        {
          "summary": "one warm sentence describing today's nutritional approach",
          "recipes": [
            {
              "name": "short evocative name (max 6 words)",
              "time": "Morning" | "Midday" | "Evening",
              "why": "ONE warm sentence (max 18 words) tying it to her \(phase.name) phase",
              "ingredients": ["7-9 ingredient lines for 1 serving, each as 'quantity unit ingredient' (e.g. '80 g rolled oats', '1 tbsp tahini', '½ tsp ground ginger') — main components in substantive amounts, condiments/spices in proportionally smaller ones"],
              "steps": ["3-5 brief prep steps, one sentence each"]
            }
          ]
        }
        """

        do {
            let text = try await callAnthropic(prompt: prompt)
            let cleaned = text
                .replacingOccurrences(of: "^```(?:json)?[\\s\\r\\n]*", with: "", options: .regularExpression)
                .replacingOccurrences(of: "[\\s\\r\\n]*```\\s*$", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let decoded = try JSONDecoder().decode(RecipeResponse.self, from: Data(cleaned.utf8))
            guard decoded.recipes.count >= 1 else { throw URLError(.badServerResponse) }

            let newRecipes = decoded.recipes.map { r in
                Recipe(name: r.name, time: r.time, why: r.why,
                       ingredients: r.ingredients, steps: r.steps,
                       icon: defaultIcon(for: phase.name),
                       phase: phase.name)
            }
            dailyNourishment = newRecipes
            dailySummary = decoded.summary ?? ""
            nourishmentDate = today
            let newNames = newRecipes.map { $0.name }
            recentRecipeNames = Array((newNames + recentRecipeNames).prefix(21))
        } catch {
            nourishmentError = error.localizedDescription
        }

        nourishmentLoading = false
    }

    private func defaultIcon(for phase: String) -> String {
        switch phase {
        case "Menstrual":  return "bowl"
        case "Follicular": return "leaf"
        case "Ovulatory":  return "fruit"
        default:           return "salmon"
        }
    }

    func clearNourishmentCache() {
        dailyNourishment = []
        nourishmentDate = ""
        dailySummary = ""
    }

    // MARK: - HealthKit connect flow

    func connectHealthKit() async {
        healthKitLoading = true
        healthKitError = nil
        do {
            try await HealthKitManager.shared.requestAuthorization()
            profile.healthKitConnected = true
            await loadCycleData()
        } catch {
            healthKitError = "Couldn't connect to Apple Health. You can try again from Settings."
        }
        healthKitLoading = false
        advance()
    }

    func loadCycleData() async {
        let (day, length) = await HealthKitManager.shared.fetchCycleData()
        cycleDay = day
        cycleLength = length
    }

    // MARK: - Navigation

    func advance() {
        switch screen {
        case .connect:             screen = .signupSymptoms
        case .signupSymptoms:      screen = .signupDiet
        case .signupDiet:          screen = .signupCookingStyle
        case .signupCookingStyle:  screen = .signupNotes
        case .signupNotes:         screen = .home
        case .home:                break
        }
    }

    func back() {
        switch screen {
        case .signupDiet:          screen = .signupSymptoms
        case .signupCookingStyle:  screen = .signupDiet
        case .signupNotes:         screen = .signupCookingStyle
        default:                   break
        }
    }
}
