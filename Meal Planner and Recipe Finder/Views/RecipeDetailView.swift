//
//  RecipeDetailView.swift
//  Meal Planner and Recipe Finder
//
//  Created by Ayush Wattamwar on 3/27/25.
//

import SwiftUI

struct RecipeDetailView: View { 
    let recipe: Recipe 
    @ObservedObject var recipesVM: RecipesViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var fullRecipe: Recipe?
    @State private var isSaved: Bool
    
    init(recipe: Recipe, recipesVM: RecipesViewModel) {
        self.recipe = recipe
        self.recipesVM = recipesVM
        _isSaved = State(initialValue: recipesVM.isRecipeSaved(recipe))
    }
    
    private var currentRecipe: Recipe {
        fullRecipe ?? recipe
    }
    
    private var caloriesPerServing: Int {
        let servings = currentRecipe.yield > 0 ? currentRecipe.yield : 1
        return Int(currentRecipe.calories / servings)
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if recipesVM.isLoadingRecipeDetails && fullRecipe == nil {
                    VStack {
                        ProgressView()
                            .controlSize(.large)
                        Text("Loading recipe details...")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    recipeContent
                }
            }
            .navigationTitle("Recipe Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if fullRecipe == nil {
                    Task {
                        fullRecipe = await recipesVM.getRecipeDetails(query: recipe.label)
                    }
                }
            }
        }
    }
    
    private var recipeContent: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    AsyncImage(url: URL(string: currentRecipe.image)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                    } placeholder: {
                        Rectangle()
                            .fill(.gray.opacity(0.2))
                            .frame(height: 200)
                    }
                    
                    Text(currentRecipe.label)
                        .font(.title2)
                        .bold()
                    
                    if !currentRecipe.cuisineType.isEmpty {
                        Text(currentRecipe.cuisineType.joined(separator: ", ").capitalized)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Source: \(currentRecipe.source)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 8)
                
                if isSaved {
                    Button(role: .destructive) {
                        recipesVM.removeRecipe(currentRecipe)
                        isSaved = false
                    } label: {
                        HStack {
                            Text("Remove Recipe")
                            Spacer()
                            Image(systemName: "trash")
                        }
                    }
                } else {
                    Button {
                        recipesVM.saveRecipe(currentRecipe)
                        isSaved = true
                    } label: {
                        HStack {
                            Text("Save Recipe")
                            Spacer()
                            Image(systemName: "heart")
                        }
                    }
                }
            }
            
            Section("Nutritional Information") {
                NutritionRow(label: "Calories", value: caloriesPerServing)
                NutritionRow(label: "Servings", value: Int(currentRecipe.yield))
                NutritionRow(label: "Total Time", value: Int(currentRecipe.totalTime), unit: "min")
                
                if !currentRecipe.dietLabels.isEmpty {
                    HStack {
                        Text("Diet Labels")
                        Spacer()
                        Text(currentRecipe.dietLabels.joined(separator: ", "))
                            .foregroundStyle(.secondary)
                    }
                }
                
                if !currentRecipe.healthLabels.isEmpty {
                    HStack {
                        Text("Health Labels")
                        Spacer()
                        Text(currentRecipe.healthLabels.joined(separator: ", "))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            if !currentRecipe.ingredientLines.isEmpty {
                Section("Ingredients") {
                    ForEach(currentRecipe.ingredientLines, id: \.self) { ingredient in
                        Text(ingredient)
                    }
                }
            }
            
            if !currentRecipe.mealType.isEmpty {
                Section("Meal Type") {
                    Text(currentRecipe.mealType.joined(separator: ", ").capitalized)
                }
            }
            
            Section {
                if let url = URL(string: currentRecipe.url) {
                    Link(destination: url) {
                        HStack {
                            Text("View Original Recipe")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                        }
                    }
                } else {
                    Text("Recipe URL unavailable")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct NutritionRow: View {
    let label: String
    let value: Int
    var unit: String = ""
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(value)\(unit.isEmpty ? "" : " \(unit)")")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    RecipeDetailView(recipe: Recipe.preview, recipesVM: RecipesViewModel(
        recipeService: RecipeService()
    ))
} 
