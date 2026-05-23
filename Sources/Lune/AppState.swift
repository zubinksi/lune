import SwiftUI
import Combine

enum AppScreen: String {
    case connect
    case signupSymptoms
    case signupDiet
    case signupNotes
    case signupAPIKey
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
        guard !profile.healthKitConnected, let refDate = profile.referencePeriodDate else { return }
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let ref = cal.startOfDay(for: refDate)
        let days = cal.dateComponents([.day], from: ref, to: today).day ?? 0
        guard days >= 0 else { return }
        let length = max(profile.manualCycleLength, 1)
        cycleLength = length
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
        }
        defaults.set(cycleDay, forKey: "cycleDay")
        defaults.set(cycleLength, forKey: "cycleLength")
    }

    func todayString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    // MARK: - Daily nourishment generation

    func loadDailyNourishment() async {
        let today = todayString()
        guard nourishmentDate != today || dailyNourishment.isEmpty else { return }

        nourishmentLoading = true

        let phase = phaseInfo
        let symptoms = profile.symptoms.isEmpty ? "none" : profile.symptoms.joined(separator: ", ")
        let diet = profile.diet.isEmpty ? "no restrictions" : profile.diet.joined(separator: ", ")
        let mood = dailyLog.mood ?? "not logged"
        let notes = profile.notes.trimmingCharacters(in: .whitespacesAndNewlines)

        let prompt = """
        You are a warm, knowledgeable nutritionist who designs meals around the menstrual cycle.

        Generate exactly 3 complete recipes for someone in their \(phase.name) phase, day \(cycleDay) of a \(cycleLength)-day cycle.

        Context:
        - Symptoms to address: \(symptoms)
        - Dietary preferences: \(diet)
        - How she feels today: \(mood)
        - Personal notes: \(notes.isEmpty ? "none" : notes)

        Each recipe should be doable in 30 minutes or less and specifically suited to the \(phase.name) phase. Vary the meal timing: one morning, one midday, one evening.

        Respond with ONLY a valid JSON object — no prose, no markdown, no code fences:

        {
          "recipes": [
            {
              "name": "short evocative name (max 6 words)",
              "time": "Morning" | "Midday" | "Evening",
              "why": "ONE warm sentence (max 18 words) tying it to her \(phase.name) phase",
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

            let decoded = try JSONDecoder().decode(RecipeResponse.self, from: Data(cleaned.utf8))
            guard decoded.recipes.count >= 1 else { throw URLError(.badServerResponse) }

            dailyNourishment = decoded.recipes.map { r in
                Recipe(name: r.name, time: r.time, why: r.why,
                       ingredients: r.ingredients, steps: r.steps,
                       icon: defaultIcon(for: phase.name),
                       phase: phase.name)
            }
            nourishmentDate = today
        } catch {
            // Fall back silently — HomeScreen shows static cards when dailyNourishment is empty
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
        case .connect:        screen = .signupSymptoms
        case .signupSymptoms: screen = .signupDiet
        case .signupDiet:     screen = .signupNotes
        case .signupNotes:    screen = .signupAPIKey
        case .signupAPIKey:   screen = .home
        case .home:           break
        }
    }

    func back() {
        switch screen {
        case .signupDiet:     screen = .signupSymptoms
        case .signupNotes:    screen = .signupDiet
        case .signupAPIKey:   screen = .signupNotes
        default:              break
        }
    }
}
