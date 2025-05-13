//
//  CreateMealViewModel.swift
//  Meal Planner and Recipe Finder
//
//  Created by Ayush Wattamwar on 3/27/25.
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
class CreateMealViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var mealType: String = "Breakfast"
    @Published var dietaryRestrictions: Set<String> = []
    @Published var calorieTarget: String = ""
    @Published var searchResults: [Recipe] = []
    @Published var selectedRecipe: Recipe?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    let recipeService: RecipeService
    private var modelContext: ModelContext?
    
    init(recipeService: RecipeService) {
        self.recipeService = recipeService
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        print("CreateMealViewModel: ModelContext set")
    }
    
    private func caloriesPerServing(for recipe: Recipe) -> Double {
        let servings = recipe.yield > 0 ? recipe.yield : 1
        return recipe.calories / servings
    }
    
    func searchRecipes() async {
        isLoading = true
        errorMessage = nil
        searchResults = []
        selectedRecipe = nil
      
        let restrictions = Array(dietaryRestrictions)
        
        let maxCalories = Int(calorieTarget)
        
        let query = searchQuery.isEmpty ? mealType : searchQuery
        
        do {
            // Fetch recipes from API
            let apiRecipes = try await recipeService.searchRecipes(
                query: query,
                mealType: mealType,
                dietaryRestrictions: restrictions,
                maxCalories: maxCalories
            )
            
            let recipes = apiRecipes.map { apiRecipe in
                createRecipeModel(from: apiRecipe)
            }
            
            var filteredResults = recipes
            if let maxCalories = maxCalories {
                filteredResults = recipes.filter { recipe in
                    caloriesPerServing(for: recipe) <= Double(maxCalories)
                }
            }
            
            // Sort by calories serveing (high to low)
            self.searchResults = filteredResults.sorted { first, second in
                caloriesPerServing(for: first) > caloriesPerServing(for: second)
            }
            
            if self.searchResults.isEmpty {
                if maxCalories != nil {
                    self.errorMessage = "No recipes found under \(calorieTarget) calories. Try increasing your calorie target."
                } else {
                    self.errorMessage = "No recipes found matching your criteria. Try adjusting your filters."
                }
            }
        } catch RecipeError.noResults {
            self.errorMessage = "No recipes found matching your criteria. Try adjusting your filters."
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        self.isLoading = false
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
        
        // recipe model
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
            isSaved: false
        )
        
        if let modelContext = modelContext {
            modelContext.insert(recipe)
        }
        
        return recipe
    }
    
    private func createNutrient(from apiNutrient: APINutrient) -> Nutrient {
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
} 
