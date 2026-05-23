import Foundation

// MARK: - Profile
struct Profile: Codable {
    var name: String = "Genesha"
    var symptoms: [String] = []
    var diet: [String] = []
    var notes: String = ""
    var healthKitConnected: Bool = false
    var manualCycleLength: Int = 28
    var referencePeriodDate: Date? = nil
}

// MARK: - Cycle
struct CycleHistory: Codable, Identifiable {
    var id = UUID()
    var startDate: Date
    var length: Int
}

// MARK: - Daily Log
struct DailyLog: Codable {
    var mood: String? = nil          // Steady | Tender | Tired | Bright | Bloated
    var hydration: Int = 0           // 0–8
    var symptomLog: [String: String] = [:]  // symptomName → Worse|Same|Better
}

// MARK: - Recipe
struct Recipe: Codable, Identifiable {
    var id = UUID()
    var name: String
    var time: String
    var why: String
    var ingredients: [String]
    var steps: [String]
    var icon: String
    var saved: Bool = false
    var phase: String = ""
}

// MARK: - Cycle Phase
struct CyclePhaseInfo {
    let name: String
    let phase: Double   // 0..1 moon phase
    let color: String   // hex
}

func cyclePhase(day: Int, length: Int = 28) -> CyclePhaseInfo {
    if day <= 5 {
        return CyclePhaseInfo(
            name: "Menstrual",
            phase: Double(day - 1) * 0.01,
            color: "#9a4a3e"
        )
    } else if day <= 13 {
        return CyclePhaseInfo(
            name: "Follicular",
            phase: 0.08 + (Double(day - 6) / 7.0) * 0.34,
            color: "#8a9a7a"
        )
    } else if day <= 16 {
        return CyclePhaseInfo(
            name: "Ovulatory",
            phase: 0.5,
            color: "#c9856b"
        )
    } else {
        return CyclePhaseInfo(
            name: "Luteal",
            phase: 0.55 + (Double(day - 17) / Double(length - 17)) * 0.4,
            color: "#b67a5e"
        )
    }
}

// MARK: - Static meal data (tuned per phase)
let defaultRecipes: [String: [Recipe]] = [
    "Menstrual": [
        Recipe(name: "Warm lentil & spinach soup", time: "Morning", why: "Iron-rich warmth for the reset phase.", ingredients: [], steps: [], icon: "bowl"),
        Recipe(name: "Dark chocolate & walnut oats", time: "Midday", why: "Magnesium ease for cramps and mood.", ingredients: [], steps: [], icon: "seed"),
        Recipe(name: "Slow-cooked chickpea stew", time: "Evening", why: "Warming iron and fibre to replenish.", ingredients: [], steps: [], icon: "leaf"),
    ],
    "Follicular": [
        Recipe(name: "Avocado & poached egg toast", time: "Morning", why: "Light protein for rising estrogen energy.", ingredients: [], steps: [], icon: "bowl"),
        Recipe(name: "Quinoa & roasted veg salad", time: "Midday", why: "Fresh, raw foods support your building phase.", ingredients: [], steps: [], icon: "leaf"),
        Recipe(name: "Lemon herb salmon fillet", time: "Evening", why: "Omega-3s and lean protein for growth.", ingredients: [], steps: [], icon: "salmon"),
    ],
    "Ovulatory": [
        Recipe(name: "Berry chia smoothie bowl", time: "Morning", why: "Cooling antioxidants for peak warmth.", ingredients: [], steps: [], icon: "fruit"),
        Recipe(name: "Fibre-rich grain & cucumber bowl", time: "Midday", why: "Cooling fibre helps process hormonal warmth.", ingredients: [], steps: [], icon: "bowl"),
        Recipe(name: "Stuffed pepper with brown rice", time: "Evening", why: "Fibre and colour at your most vibrant.", ingredients: [], steps: [], icon: "leaf"),
    ],
    "Luteal": [
        Recipe(name: "Oat porridge, banana, pumpkin seeds", time: "Morning", why: "Magnesium and slow carbs to soften cramping before it lands.", ingredients: [], steps: [], icon: "bowl"),
        Recipe(name: "Salmon over fennel & cucumber", time: "Midday", why: "Omega-3s and fennel help with luteal-phase bloating.", ingredients: [], steps: [], icon: "salmon"),
        Recipe(name: "Sweet potato & lentil bowl", time: "Evening", why: "Complex carbs and B vitamins steady mood as progesterone climbs.", ingredients: [], steps: [], icon: "leaf"),
    ],
]

let phaseExplainer: [String: String] = [
    "Menstrual": "Your body is shedding and resetting. Iron-rich, warming foods help replenish what's lost — think slow-cooked stews and dark leafy greens.",
    "Follicular": "Estrogen is rising and so is your energy. Fresh, raw foods and light proteins support the building-up your body is doing.",
    "Ovulatory": "Peak energy and warmth. Cooling, fibre-rich foods help process the natural rise in temperature and hormones.",
    "Luteal": "Progesterone is climbing, which can mean bloating, cravings, and a tender mood. Magnesium-rich foods and warming spices help you ride the wave.",
]

let phaseFoods: [String: [String]] = [
    "Menstrual": ["dark leafy greens", "lentils", "ginger", "dark chocolate", "bone broth"],
    "Follicular": ["eggs", "light greens", "fermented foods", "seeds", "lean protein"],
    "Ovulatory": ["berries", "flax seeds", "cucumber", "quinoa", "turmeric"],
    "Luteal": ["pumpkin seeds", "dark leafy greens", "sweet potato", "salmon", "ginger", "dark chocolate"],
]
