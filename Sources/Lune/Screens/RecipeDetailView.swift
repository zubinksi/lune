import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    let currentPhase: String
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var tweakedRecipe: Recipe? = nil
    @State private var tweakText = ""
    @State private var tweakLoading = false

    var display: Recipe { tweakedRecipe ?? recipe }

    var isSaved: Bool {
        appState.savedRecipes.contains { $0.name == display.name }
    }

    var iconColor: Color {
        switch display.icon {
        case "salmon": return .lTerracottaDeep
        case "leaf":   return .lSage
        default:       return .lTerracotta
        }
    }

    private var attributeChips: [String] {
        var chips = [currentPhase, appState.currentSeason().capitalized]
        if let mood = appState.dailyLog.mood { chips.append(mood) }
        chips.append(contentsOf: appState.profile.diet.prefix(2))
        return chips
    }

    private var tweakPresets: [String] {
        switch currentPhase {
        case "Menstrual":  return ["make it warmer", "more iron", "no dairy"]
        case "Follicular": return ["more protein", "make it raw", "lighter"]
        case "Ovulatory":  return ["more cooling", "add flax seeds", "less heat"]
        case "Luteal":     return ["add dark chocolate", "more magnesium", "swap to lentils"]
        default:           return ["make it vegan", "swap the protein", "lighter version"]
        }
    }

    private var canTweak: Bool {
        !tweakText.trimmingCharacters(in: .whitespaces).isEmpty && !tweakLoading
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.lCream.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: 72)

                    // Icon + phase/time pill
                    HStack(alignment: .center, spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.lPaper)
                                .frame(width: 72, height: 72)
                                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.lRule, lineWidth: 1))
                            FoodIconView(kind: display.icon, size: 46, color: iconColor)
                        }

                        HStack(spacing: 5) {
                            Text(currentPhase)
                                .font(LFont.mono(9.5))
                                .tracking(0.8)
                                .foregroundColor(.lPlum)
                            Text("·")
                                .font(LFont.mono(9.5))
                                .foregroundColor(.lInk3)
                            Text(display.time)
                                .font(LFont.mono(9.5))
                                .tracking(0.8)
                                .foregroundColor(.lInk3)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.lPlum.opacity(0.06))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.lPlum.opacity(0.15), lineWidth: 1))
                    }

                    Spacer().frame(height: 20)

                    // Recipe name
                    Text(display.name)
                        .font(LFont.display(30))
                        .foregroundColor(.lInk)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer().frame(height: 10)

                    // Why (italic)
                    Text(display.why)
                        .font(LFont.body(15))
                        .italic()
                        .foregroundColor(.lInk2)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer().frame(height: 20)

                    // "Why this, for you today" card
                    VStack(alignment: .leading, spacing: 10) {
                        Eyebrow("Why this, for you today")

                        FlowLayout(spacing: 6) {
                            ForEach(attributeChips, id: \.self) { chip in
                                Text(chip)
                                    .font(LFont.body(12))
                                    .foregroundColor(.lPlum)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.lPlum.opacity(0.08))
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(Color.lPlum.opacity(0.2), lineWidth: 1))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.lPlum.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.lPlum.opacity(0.12), lineWidth: 1))

                    Spacer().frame(height: 28)

                    // Ingredients
                    if !display.ingredients.isEmpty {
                        Eyebrow("Ingredients")
                        Spacer().frame(height: 12)
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(display.ingredients, id: \.self) { item in
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

                    // Steps
                    if !display.steps.isEmpty {
                        Eyebrow("How to make it")
                        Spacer().frame(height: 12)
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(display.steps.enumerated()), id: \.offset) { i, step in
                                HStack(alignment: .top, spacing: 12) {
                                    Text(String(format: "%02d", i + 1))
                                        .font(LFont.mono(10))
                                        .tracking(1)
                                        .foregroundColor(.lInk3)
                                        .padding(.top, 3)
                                    Text(step)
                                        .font(LFont.body(14))
                                        .foregroundColor(.lInk2)
                                        .lineSpacing(3)
                                }
                            }
                        }
                        Spacer().frame(height: 32)
                    }

                    // Tweak with Ona
                    VStack(alignment: .leading, spacing: 12) {
                        Eyebrow("Tweak with Ona")

                        FlowLayout(spacing: 6) {
                            ForEach(tweakPresets, id: \.self) { preset in
                                Button {
                                    tweakText = tweakText == preset ? "" : preset
                                } label: {
                                    Text(preset)
                                        .font(LFont.body(12))
                                        .foregroundColor(tweakText == preset ? .lPlum : .lInk2)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(tweakText == preset ? Color.lPlum.opacity(0.08) : Color.lCream2)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(
                                            tweakText == preset ? Color.lPlum.opacity(0.3) : Color.lRule, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        HStack(spacing: 8) {
                            TextField("e.g. swap walnuts, make it dairy-free…", text: $tweakText)
                                .font(LFont.body(14))
                                .foregroundColor(.lInk)
                                .autocorrectionDisabled()
                                .onSubmit { Task { await performTweak() } }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Color.lPaper)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.lRule, lineWidth: 1))

                            Button { Task { await performTweak() } } label: {
                                Text(tweakLoading ? "…" : "Go")
                                    .font(LFont.body(14, weight: .medium))
                                    .foregroundColor(canTweak ? .lCream : .lInk3)
                                    .frame(width: 52, height: 52)
                                    .background(canTweak ? Color.lPlum : Color.lCream2)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .disabled(!canTweak)
                        }

                        if tweakedRecipe != nil {
                            Button {
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    tweakedRecipe = nil
                                    tweakText = ""
                                }
                            } label: {
                                Text("← restore original")
                                    .font(LFont.body(12.5))
                                    .foregroundColor(.lInk3)
                            }
                        }
                    }

                    Spacer().frame(height: 24)

                    // Save + Share
                    HStack(spacing: 10) {
                        Button {
                            if isSaved {
                                appState.savedRecipes.removeAll { $0.name == display.name }
                            } else {
                                var r = display
                                r.phase = currentPhase
                                appState.savedRecipes.append(r)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                    .font(.system(size: 13, weight: .regular))
                                Text(isSaved ? "Saved" : "Save")
                                    .font(LFont.body(13))
                            }
                            .foregroundColor(isSaved ? .lPlum : .lInk2)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(isSaved ? Color.lPlum.opacity(0.08) : Color.lPaper)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(isSaved ? Color.lPlum.opacity(0.3) : Color.lRule, lineWidth: 1))
                        }
                        .animation(.easeInOut(duration: 0.15), value: isSaved)

                        ShareLink(item: recipeShareText(display)) {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 13, weight: .regular))
                                Text("Share")
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
                    }

                    Spacer().frame(height: 60)
                }
                .padding(.horizontal, 24)
            }

            // Top bar
            HStack {
                Button { dismiss() } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .medium))
                        Text("Back")
                            .font(LFont.body(15))
                    }
                    .foregroundColor(.lPlum)
                }
                Spacer()
                if display.ingredients.isEmpty && display.steps.isEmpty {
                    EmptyView()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .background(Color.lCream)
        }
        .presentationBackground(Color.lCream)
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
            let updated = Recipe(
                name: result.name, time: result.time, why: result.why,
                ingredients: result.ingredients, steps: result.steps,
                icon: recipe.icon, phase: currentPhase
            )
            withAnimation(.easeInOut(duration: 0.18)) {
                tweakedRecipe = updated
                tweakText = ""
            }
        } catch { }
        tweakLoading = false
    }
}
