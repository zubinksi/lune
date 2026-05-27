import Foundation

// MARK: - Profile
struct Profile: Codable {
    var name: String = ""
    var symptoms: [String] = []
    var diet: [String] = []
    var cookingStyles: [String] = []
    var cookingStyleNotes: String = ""
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
    "Menstrual": "Your body is shedding and resetting — a time for warmth and replenishment.",
    "Follicular": "Estrogen is rising and so is your energy — a good time to build and experiment.",
    "Ovulatory": "Peak energy and warmth — cooling, fibre-rich foods help you stay balanced.",
    "Luteal": "Progesterone is climbing — magnesium-rich foods and warming spices help you ride the wave.",
]

let phaseFoods: [String: [String]] = [
    "Menstrual": ["dark leafy greens", "lentils", "ginger", "dark chocolate", "bone broth"],
    "Follicular": ["eggs", "light greens", "fermented foods", "seeds", "lean protein"],
    "Ovulatory": ["berries", "flax seeds", "cucumber", "quinoa", "turmeric"],
    "Luteal": ["pumpkin seeds", "dark leafy greens", "sweet potato", "salmon", "ginger", "dark chocolate"],
]

struct PhaseDetail {
    let days: String
    let hormones: String
    let youMightNotice: [String]
    let nutritionFocus: String
}

let phaseDetails: [String: PhaseDetail] = [
    "Menstrual": PhaseDetail(
        days: "Days 1–5",
        hormones: "Estrogen and progesterone drop to their lowest levels, signalling the uterine lining to shed. This is a time of release and reset — the body clears the slate for a new cycle.",
        youMightNotice: [
            "Cramping or lower back ache",
            "Fatigue and a need for more rest",
            "Heightened sensitivity or emotional depth",
            "A natural pull toward slowness and quiet",
        ],
        nutritionFocus: "Replenish the iron lost through bleeding with dark leafy greens, lentils, and bone broth. Anti-inflammatory foods like ginger and turmeric ease cramping. Warm, easy-to-digest meals are kinder on the system than raw or cold foods right now."
    ),
    "Follicular": PhaseDetail(
        days: "Days 6–13",
        hormones: "FSH (follicle-stimulating hormone) rises, kick-starting follicle development in the ovaries. Estrogen climbs steadily in response — bringing with it a lift in energy, mood, and mental sharpness.",
        youMightNotice: [
            "Rising energy and motivation",
            "A clearer, more optimistic headspace",
            "Increased creativity and social ease",
            "Stronger physical endurance",
        ],
        nutritionFocus: "Your body is building. Light, fresh foods — sprouts, raw vegetables, fermented foods — support rising estrogen and gut health. Seeds like flax and pumpkin provide the fatty acids your hormones need. Lean proteins fuel the upswing in energy."
    ),
    "Ovulatory": PhaseDetail(
        days: "Days 14–16",
        hormones: "A surge of LH (luteinising hormone) triggers ovulation. Estrogen peaks and testosterone briefly rises alongside it — this is your body at its most outwardly energised and confident.",
        youMightNotice: [
            "Peak energy and physical warmth",
            "Heightened confidence and sociability",
            "Increased libido",
            "Slightly elevated body temperature",
        ],
        nutritionFocus: "Cooling, fibre-rich foods help your body process the peak in estrogen and offset the natural rise in body heat. Berries, cucumber, flax seeds, and quinoa are all well-suited here. Keep meals light and fresh rather than heavy or rich."
    ),
    "Luteal": PhaseDetail(
        days: "Days 17–28",
        hormones: "Progesterone rises to prepare the uterine lining for potential implantation. If pregnancy doesn't occur, both estrogen and progesterone fall in the final days — which is what drives PMS symptoms.",
        youMightNotice: [
            "Slowing energy and a need for more rest",
            "Bloating or water retention",
            "Cravings, especially for carbs and chocolate",
            "Mood sensitivity or emotional tenderness",
            "Breast tenderness in the latter half",
        ],
        nutritionFocus: "Magnesium is your best friend — it eases cramping, supports mood, and is found in pumpkin seeds, dark chocolate, and leafy greens. Complex carbs like sweet potato and lentils steady blood sugar and serotonin. B vitamins help the liver process the hormonal shift."
    ),
]
