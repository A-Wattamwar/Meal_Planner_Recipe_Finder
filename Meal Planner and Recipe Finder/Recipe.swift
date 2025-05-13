//
//  Recipe.swift
//  Meal Planner and Recipe Finder
//
//  Created by Ayush Wattamwar on 3/27/25.
//

import Foundation 
import SwiftUI
import SwiftData

struct APIRecipe: Identifiable, Codable, Hashable {
    let uri: String
    let label: String
    let image: String
    let source: String
    let url: String
    let yield: Double
    let dietLabels: [String]
    let healthLabels: [String]
    let cautions: [String]
    let ingredientLines: [String]
    let ingredients: [APIIngredient]
    let calories: Double
    let totalWeight: Double
    let totalTime: Double
    let cuisineType: [String]
    let mealType: [String]
    let dishType: [String]
    let totalNutrients: APINutrientsInfo
    
    var id: String {
        uri
    }
    
    var formattedCalories: String {
        String(format: "%.0f", calories)
    }
    
    var formattedCookingTime: String {
        if totalTime <= 0 {
            return "N/A"
        }
        return "\(Int(totalTime)) min"
    }
    
    var formattedServings: String {
        if yield <= 0 {
            return "N/A"
        }
        return "\(Int(yield)) servings"
    }
}

struct APIIngredient: Codable, Hashable {
    let text: String
    let quantity: Double
    let measure: String?
    let food: String
    let weight: Double
    let foodCategory: String?
    let foodId: String
    let image: String?
}

struct APINutrientsInfo: Codable, Hashable {
    let ENERC_KCAL: APINutrient
    let FAT: APINutrient
    let CHOCDF: APINutrient
    let PROCNT: APINutrient
    let CHOLE: APINutrient
    let NA: APINutrient
    let CA: APINutrient
    let MG: APINutrient
    let K: APINutrient
    let FE: APINutrient
    let FIBTG: APINutrient
    let SUGAR: APINutrient
}

struct APINutrient: Codable, Hashable {
    let label: String
    let quantity: Double
    let unit: String
}

struct RecipeSearchResponse: Codable {
    let from: Int
    let to: Int
    let count: Int
    let hits: [RecipeHit]
}

struct RecipeHit: Codable {
    let recipe: APIRecipe
}

@Model
final class Recipe {
    @Attribute(.unique) var uri: String
    var label: String
    var image: String
    var source: String
    var url: String
    var yield: Double
    var dietLabels: [String]
    var healthLabels: [String]
    var cautions: [String]
    var ingredientLines: [String]
    @Relationship var ingredients: [Ingredient]?
    var calories: Double
    var totalWeight: Double
    var totalTime: Double
    var cuisineType: [String]
    var mealType: [String]
    var dishType: [String]
    @Relationship var totalNutrients: NutrientsInfo?
    var isSaved: Bool = false
    
    var id: String {
        uri
    }

    var formattedCalories: String {
        String(format: "%.0f", calories)
    }
    
    var formattedCookingTime: String {
        if totalTime <= 0 {
            return "N/A"
        }
        return "\(Int(totalTime)) min"
    }
    
    var formattedServings: String {
        if yield <= 0 {
            return "N/A"
        }
        return "\(Int(yield)) servings"
    }
    
    init(
        uri: String,
        label: String,
        image: String,
        source: String,
        url: String,
        yield: Double,
        dietLabels: [String],
        healthLabels: [String],
        cautions: [String],
        ingredientLines: [String],
        ingredients: [Ingredient]?,
        calories: Double,
        totalWeight: Double,
        totalTime: Double,
        cuisineType: [String],
        mealType: [String],
        dishType: [String],
        totalNutrients: NutrientsInfo?,
        isSaved: Bool = false
    ) {
        self.uri = uri
        self.label = label
        self.image = image
        self.source = source
        self.url = url
        self.yield = yield
        self.dietLabels = dietLabels
        self.healthLabels = healthLabels
        self.cautions = cautions
        self.ingredientLines = ingredientLines
        self.ingredients = ingredients
        self.calories = calories
        self.totalWeight = totalWeight
        self.totalTime = totalTime
        self.cuisineType = cuisineType
        self.mealType = mealType
        self.dishType = dishType
        self.totalNutrients = totalNutrients
        self.isSaved = isSaved
    }
    
    init(
        uri: String,
        label: String,
        image: String,
        source: String,
        url: String,
        yield: Double,
        dietLabels: [String],
        healthLabels: [String],
        cautions: [String],
        ingredientLines: [String],
        ingredients: [Ingredient],
        calories: Double,
        totalWeight: Double,
        totalTime: Double,
        cuisineType: [String],
        mealType: [String],
        dishType: [String],
        totalNutrients: NutrientsInfo
    ) {
        self.uri = uri
        self.label = label
        self.image = image
        self.source = source
        self.url = url
        self.yield = yield
        self.dietLabels = dietLabels
        self.healthLabels = healthLabels
        self.cautions = cautions
        self.ingredientLines = ingredientLines
        self.ingredients = ingredients
        self.calories = calories
        self.totalWeight = totalWeight
        self.totalTime = totalTime
        self.cuisineType = cuisineType
        self.mealType = mealType
        self.dishType = dishType
        self.totalNutrients = totalNutrients
    }
    
    static let preview = Recipe(
        uri: "https://example.com#recipe1",
        label: "Sample Recipe",
        image: "https://example.com/image.jpg",
        source: "Sample Source",
        url: "https://example.com",
        yield: 4,
        dietLabels: ["Gluten-free"],
        healthLabels: ["Low-sugar"],
        cautions: [],
        ingredientLines: [
            "1 cup flour",
            "2 eggs",
            "1 cup milk"
        ],
        ingredients: [],
        calories: 350,
        totalWeight: 0,
        totalTime: 0,
        cuisineType: ["Italian"],
        mealType: ["Dinner"],
        dishType: [],
        totalNutrients: NutrientsInfo(
            ENERC_KCAL: Nutrient(label: "Calories", quantity: 350, unit: "kcal"),
            FAT: Nutrient(label: "Fat", quantity: 0, unit: "g"),
            CHOCDF: Nutrient(label: "Carbohydrates", quantity: 0, unit: "g"),
            PROCNT: Nutrient(label: "Protein", quantity: 0, unit: "g"),
            CHOLE: Nutrient(label: "Cholesterol", quantity: 0, unit: "mg"),
            NA: Nutrient(label: "Sodium", quantity: 0, unit: "mg"),
            CA: Nutrient(label: "Calcium", quantity: 0, unit: "mg"),
            MG: Nutrient(label: "Magnesium", quantity: 0, unit: "mg"),
            K: Nutrient(label: "Potassium", quantity: 0, unit: "mg"),
            FE: Nutrient(label: "Iron", quantity: 0, unit: "mg"),
            FIBTG: Nutrient(label: "Fiber", quantity: 0, unit: "g"),
            SUGAR: Nutrient(label: "Sugar", quantity: 0, unit: "g")
        )
    )
}

@Model
final class Ingredient {
    @Attribute(.unique) var id = UUID()
    var text: String
    var quantity: Double
    var measure: String?
    var food: String
    var weight: Double
    var foodCategory: String?
    var foodId: String
    var image: String?
    
    init(text: String, quantity: Double, measure: String?, food: String, weight: Double, foodCategory: String?, foodId: String, image: String?) {
        self.text = text
        self.quantity = quantity
        self.measure = measure
        self.food = food
        self.weight = weight
        self.foodCategory = foodCategory
        self.foodId = foodId
        self.image = image
    }
}

@Model
final class NutrientsInfo {
    @Attribute(.unique) var id = UUID()
    @Relationship var ENERC_KCAL: Nutrient?
    @Relationship var FAT: Nutrient?
    @Relationship var CHOCDF: Nutrient?
    @Relationship var PROCNT: Nutrient?
    @Relationship var CHOLE: Nutrient?
    @Relationship var NA: Nutrient?
    @Relationship var CA: Nutrient?
    @Relationship var MG: Nutrient?
    @Relationship var K: Nutrient?
    @Relationship var FE: Nutrient?
    @Relationship var FIBTG: Nutrient?
    @Relationship var SUGAR: Nutrient?
    
    init(ENERC_KCAL: Nutrient?, FAT: Nutrient?, CHOCDF: Nutrient?, PROCNT: Nutrient?, CHOLE: Nutrient?, NA: Nutrient?, CA: Nutrient?, MG: Nutrient?, K: Nutrient?, FE: Nutrient?, FIBTG: Nutrient?, SUGAR: Nutrient?) {
        self.ENERC_KCAL = ENERC_KCAL
        self.FAT = FAT
        self.CHOCDF = CHOCDF
        self.PROCNT = PROCNT
        self.CHOLE = CHOLE
        self.NA = NA
        self.CA = CA
        self.MG = MG
        self.K = K
        self.FE = FE
        self.FIBTG = FIBTG
        self.SUGAR = SUGAR
    }
}

@Model
final class Nutrient {
    @Attribute(.unique) var id = UUID()
    var label: String
    var quantity: Double
    var unit: String
    
    init(label: String, quantity: Double, unit: String) {
        self.label = label
        self.quantity = quantity
        self.unit = unit
    }
} 
