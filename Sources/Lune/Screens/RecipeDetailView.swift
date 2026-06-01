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

                        Text("Missing something or not in the mood? Tell Ona to rework it.")
                            .font(LFont.body(13))
                            .foregroundColor(.lInk2)
                            .lineSpacing(2)

                        HStack(spacing: 8) {
                            TextField("e.g. swap walnuts, make it dairy-free…", text: $tweakText)
                                .font(LFont.body(14))
                                .foregroundColor(.lInk)
                                .autocorrectionDisabled()
                                .onSubmit { Task { await performTweak() } }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Color.lCream)
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
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.lPaper)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.lRule, lineWidth: 1))

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
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(isSaved ? .lPlum : .lInk2)
                            .frame(width: 36, height: 36)
                            .background(Color.lPaper)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.lRule, lineWidth: 1))
                    }
                    .animation(.easeInOut(duration: 0.15), value: isSaved)

                    ShareLink(item: recipeShareText(display)) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.lInk2)
                            .frame(width: 36, height: 36)
                            .background(Color.lPaper)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.lRule, lineWidth: 1))
                    }
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
