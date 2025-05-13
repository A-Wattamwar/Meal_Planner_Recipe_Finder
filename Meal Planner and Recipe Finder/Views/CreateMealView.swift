//
//  CreateMealView.swift
//  Meal Planner and Recipe Finder
//
//  Created by Ayush Wattamwar on 3/27/25.
//

import SwiftUI

struct CreateMealView: View {

    @ObservedObject var viewModel: CreateMealViewModel
    @ObservedObject var recipesVM: RecipesViewModel

    @State private var showRecipeOptions = false
    @State private var showRecipeDetail = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    searchBar
                    filtersSection
                }
                .padding(.vertical)
            }
            .navigationTitle("Create Meal")
            .sheet(isPresented: $showRecipeOptions, content: recipeOptionsSheet)
            .sheet(isPresented: $showRecipeDetail, content: recipeDetailSheet)
        }
    }
}

private extension CreateMealView {

    var searchBar: some View {
        HStack {
            TextField("Search recipes...", text: $viewModel.searchQuery)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .overlay(clearButtonOverlay, alignment: .trailing)

            Button(action: performSearch) {
                Image(systemName: "magnifyingglass")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal)
    }

    var clearButtonOverlay: some View {
        Group {
            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray)
                        .padding(.trailing, 8)
                }
            }
        }
    }

    var filtersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Meal Type")

            Picker("Meal Type", selection: $viewModel.mealType) {
                ForEach(RecipesViewModel.availableMealTypes, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.segmented)

            sectionHeader("Calorie Target")

            HStack {
                TextField("Enter calories", text: $viewModel.calorieTarget)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 120)
                Text("cal")
                    .foregroundStyle(.secondary)
            }

            sectionHeader("Dietary Restrictions")

            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 2), spacing: 12) {
                ForEach(RecipesViewModel.availableDietaryRestrictions, id: \.self) { option in
                    Toggle(option, isOn: Binding(
                        get: { viewModel.dietaryRestrictions.contains(option) },
                        set: {
                            if $0 { viewModel.dietaryRestrictions.insert(option) }
                            else  { viewModel.dietaryRestrictions.remove(option) }
                        }))
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
        .padding(.horizontal)
    }

    func sectionHeader(_ title: String) -> some View {
        Text(title).font(.headline)
    }
}

private extension CreateMealView {

    @ViewBuilder
    func recipeOptionsSheet() -> some View {
        NavigationStack {
            ScrollView {
                if viewModel.isLoading {
                    ContentLoadingView()
                } else if !viewModel.searchResults.isEmpty {
                    RecipeResultsView(
                        recipes: viewModel.searchResults,
                        onRecipeSelected: handleRecipeSelection(_:))
                } else if let error = viewModel.errorMessage {
                    ContentErrorView(message: error)
                }
            }
            .navigationTitle("Recipe Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showRecipeOptions = false }
                }
            }
        }
        .presentationDetents([.large])
    }

    @ViewBuilder
    func recipeDetailSheet() -> some View {
        if let recipe = viewModel.selectedRecipe {
            RecipeDetailView(recipe: recipe, recipesVM: recipesVM)
        }
    }
}

private extension CreateMealView {

    func performSearch() {
        Task {
            await viewModel.searchRecipes()
            if !viewModel.searchResults.isEmpty || viewModel.errorMessage != nil {
                showRecipeOptions = true
            }
        }
    }

    func handleRecipeSelection(_ recipe: Recipe) {
        recipe.mealType = [viewModel.mealType]
        viewModel.selectedRecipe = recipe
        showRecipeOptions = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showRecipeDetail = true
        }
    }
}

#Preview {
    let service = RecipeService(appId: "0a7189c7", appKey: "9d11e54ebbfc928900f654db1e5f908f")
    return CreateMealView(
        viewModel: CreateMealViewModel(recipeService: service),
        recipesVM: RecipesViewModel(recipeService: service)
    )
    .modelContainer(for: [Recipe.self, Ingredient.self, NutrientsInfo.self, Nutrient.self], inMemory: true)
}
