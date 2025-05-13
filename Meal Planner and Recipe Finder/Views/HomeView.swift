//
//  HomeView.swift
//  Meal Planner and Recipe Finder
//
//  Created by Ayush Wattamwar on 3/29/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @ObservedObject var recipesVM: RecipesViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var selectedRecipe: Recipe?
    @State private var showingRecipeDetail = false
    
    private var filteredRecipes: [Recipe] {
        var recipes = recipesVM.savedRecipes
        
        if !searchText.isEmpty {
            recipes = recipes.filter { $0.label.localizedCaseInsensitiveContains(searchText) }
        }
        
        if let category = selectedCategory, category != "All" {
            recipes = recipes.filter { !$0.mealType.filter { $0.localizedCaseInsensitiveContains(category) }.isEmpty }
        }
        
        return recipes
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Search Bar
                    HStack {
                        TextField("Search saved recipes...", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .overlay {
                                if !searchText.isEmpty {
                                    HStack {
                                        Spacer()
                                        Button {
                                            searchText = ""
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(.gray)
                                        }
                                        .padding(.trailing, 8)
                                    }
                                }
                            }
                    }
                    .padding(.horizontal)
                    
                    // Categories
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(RecipesViewModel.availableMealTypes, id: \.self) { category in
                                Button {
                                    selectedCategory = (selectedCategory == category) ? nil : category
                                } label: {
                                    Text(category)
                                        .font(.subheadline)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedCategory == category ? .blue : .gray.opacity(0.15))
                                        .foregroundStyle(selectedCategory == category ? .white : .primary)
                                        .clipShape(.capsule)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    if recipesVM.savedRecipes.isEmpty {
                        ContentUnavailableView {
                            Label("No Saved Recipes", systemImage: "heart")
                        } description: {
                            Text("Your saved recipes will appear here")
                        }
                    } else if filteredRecipes.isEmpty {
                        ContentUnavailableView {
                            Label("No Matching Recipes", systemImage: "magnifyingglass")
                        } description: {
                            Text("Try adjusting your search or filters")
                        }
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredRecipes) { recipe in
                                RecipeCard(recipe: recipe) {
                                    selectedRecipe = recipe
                                    showingRecipeDetail = true
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Saved Recipes")
            .sheet(item: $selectedRecipe) { recipe in
                RecipeDetailView(recipe: recipe, recipesVM: recipesVM)
            }
        }
    }
}
 
#Preview { 
    // Use placeholder API keys for preview
    let recipeService = RecipeService(
        appId: "preview_app_id",
        appKey: "preview_app_key"
    )
    let recipesVM = RecipesViewModel(recipeService: recipeService)
    
    return HomeView(recipesVM: recipesVM)
        .modelContainer(for: [Recipe.self, Ingredient.self, NutrientsInfo.self, Nutrient.self], inMemory: true)
}
