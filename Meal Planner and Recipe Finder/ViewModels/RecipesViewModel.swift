//
//  RecipesViewModel.swift
//  Meal Planner and Recipe Finder
//
//  Created by Ayush Wattamwar on 3/27/25.
//

import Foundation
import SwiftUI
import SwiftData 

@MainActor
final class RecipesViewModel: ObservableObject {
    @Published private(set) var recipes: [Recipe] = []
    @Published private(set) var error: Error?
    @Published var isLoading = false
    @Published var isLoadingRecipeDetails = false
    @Published var searchQuery = ""
    @Published var selectedMealType: String?
    @Published var selectedDietaryRestrictions: Set<String> = []
    @Published var maxCalories: Int?
    
    private let recipeService: RecipeService
    private var modelContext: ModelContext?
     
    init(recipeService: RecipeService) {
        self.recipeService = recipeService
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        print("RecipesViewModel: ModelContext set")
    }
    
    var savedRecipes: [Recipe] {
        guard let modelContext = modelContext else { return [] }
        
        do {
            let descriptor = FetchDescriptor<Recipe>(predicate: #Predicate { recipe in
                recipe.isSaved == true
            })
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching saved recipes: \(error)")
            return []
        }
    }

    func searchRecipes() async {
        guard !searchQuery.isEmpty else { return }
        do {
            let apiRecipes = try await recipeService.searchRecipes(
                query: searchQuery,
                mealType: selectedMealType,
                dietaryRestrictions: Array(selectedDietaryRestrictions),
                maxCalories: maxCalories
            )
            
            // change API recipes to SwiftData models
            self.recipes = apiRecipes.map { apiRecipe in
                createRecipeModel(from: apiRecipe)
            }
            self.error = nil
        } catch {
            self.error = error
            self.recipes = []
        }
    }
    
    
    func getRecipeDetails(query: String) async -> Recipe? {
        isLoadingRecipeDetails = true
        defer { isLoadingRecipeDetails = false }
        
        do {
            let apiRecipes = try await recipeService.searchRecipes(query: query)
            if let firstRecipe = apiRecipes.first {
                return createRecipeModel(from: firstRecipe)
            }
            return nil
        } catch {
            self.error = error
            return nil
        }
    }
    
    private func createRecipeModel(from apiRecipe: APIRecipe) -> Recipe {
        if let existingRecipe = findRecipe(by: apiRecipe.uri) {
            return existingRecipe
        }
        
        let nutrientsInfo = NutrientsInfo(
            ENERC_KCAL: createNutrient(from: apiRecipe.totalNutrients.ENERC_KCAL),
            FAT: createNutrient(from: apiRecipe.totalNutrients.FAT),
            CHOCDF: createNutrient(from: apiRecipe.totalNutrients.CHOCDF),
            PROCNT: createNutrient(from: apiRecipe.totalNutrients.PROCNT),
            CHOLE: createNutrient(from: apiRecipe.totalNutrients.CHOLE),
            NA: createNutrient(from: apiRecipe.totalNutrients.NA),
            CA: createNutrient(from: apiRecipe.totalNutrients.CA),
            MG: createNutrient(from: apiRecipe.totalNutrients.MG),
            K: createNutrient(from: apiRecipe.totalNutrients.K),
            FE: createNutrient(from: apiRecipe.totalNutrients.FE),
            FIBTG: createNutrient(from: apiRecipe.totalNutrients.FIBTG),
            SUGAR: createNutrient(from: apiRecipe.totalNutrients.SUGAR)
        )
        
        let ingredients = apiRecipe.ingredients.map { apiIngredient in
            Ingredient(
                text: apiIngredient.text,
                quantity: apiIngredient.quantity,
                measure: apiIngredient.measure,
                food: apiIngredient.food,
                weight: apiIngredient.weight,
                foodCategory: apiIngredient.foodCategory,
                foodId: apiIngredient.foodId,
                image: apiIngredient.image
            )
        }
        
        let recipe = Recipe(
            uri: apiRecipe.uri,
            label: apiRecipe.label,
            image: apiRecipe.image,
            source: apiRecipe.source,
            url: apiRecipe.url,
            yield: apiRecipe.yield,
            dietLabels: apiRecipe.dietLabels,
            healthLabels: apiRecipe.healthLabels,
            cautions: apiRecipe.cautions,
            ingredientLines: apiRecipe.ingredientLines,
            ingredients: ingredients,
            calories: apiRecipe.calories,
            totalWeight: apiRecipe.totalWeight,
            totalTime: apiRecipe.totalTime,
            cuisineType: apiRecipe.cuisineType,
            mealType: apiRecipe.mealType,
            dishType: apiRecipe.dishType,
            totalNutrients: nutrientsInfo,
            isSaved: isRecipeSaved(apiRecipe)
        )

        if let modelContext = modelContext {
            modelContext.insert(recipe)
        }
        
        return recipe
    }
    
    private func createNutrient(from apiNutrient: APINutrient?) -> Nutrient? {
        guard let apiNutrient = apiNutrient else { return nil }
        
        return Nutrient(
            label: apiNutrient.label,
            quantity: apiNutrient.quantity,
            unit: apiNutrient.unit
        )
    }
    
    private func findRecipe(by uri: String) -> Recipe? {
        guard let modelContext = modelContext else { return nil }
        
        do {
            let descriptor = FetchDescriptor<Recipe>(predicate: #Predicate { recipe in
                recipe.uri == uri
            })
            let results = try modelContext.fetch(descriptor)
            return results.first
        } catch {
            print("Error finding recipe: \(error)")
            return nil
        }
    }
    
    func saveRecipe(_ recipe: Recipe) {
        guard let modelContext = modelContext else { return }
        
        if !isRecipeSaved(recipe) {
            recipe.isSaved = true
            try? modelContext.save()
            objectWillChange.send()
        }
    }
    
    func removeRecipe(_ recipe: Recipe) {
        guard let modelContext = modelContext else { return }
        
        recipe.isSaved = false
        try? modelContext.save()
        objectWillChange.send()
    }
    
    func isRecipeSaved(_ recipe: Recipe) -> Bool {
        return recipe.isSaved
    }
    
    func isRecipeSaved(_ apiRecipe: APIRecipe) -> Bool {
        return savedRecipes.contains { $0.uri == apiRecipe.uri }
    }
    
    func clearSearch() {
        searchQuery = ""
        selectedMealType = nil
        selectedDietaryRestrictions.removeAll()
        maxCalories = nil
        recipes = []
        error = nil
    }
    
    static let availableMealTypes = [
        "Breakfast",
        "Lunch",
        "Dinner",
        "Snack"
    ]
    
    static let availableDietaryRestrictions = [
        "Vegetarian",
        "Vegan",
        "Gluten-Free",
        "Dairy-Free",
        "Nut-Free",
        "Low-Carb",
        "Low-Fat",
        "High-Protein",
        "High-Fiber",
        "Low-Sodium"
    ]
} 
