//
//  RecipeService.swift
//  Meal Planner and Recipe Finder
//
//  Created by Ayush Wattamwar on 3/27/25.
//

import Foundation
import SwiftUI

enum RecipeError: Error, LocalizedError { 
    case invalidURL
    case invalidResponse
    case noData
    case decodingError
    case noResults
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Error parsing recipe data"
        case .noResults:
            return "No recipes found"
        }
    }
}

@MainActor
final class RecipeService: ObservableObject {
    @Published var isLoading = false
    @Published var error: RecipeError?
    @Published var searchResults: [APIRecipe] = []
    
    private let appId: String = Credentials.edamamAppId
    private let appKey: String = Credentials.edamamAppKey
    private let baseURL = "https://api.edamam.com/api/recipes/v2"
    
    // Mapping of diet names to Edamam API health/diet values
    private let dietMapping: [String: (type: String, value: String)] = [
        "Vegetarian": (type: "health", value: "vegetarian"),
        "Vegan": (type: "health", value: "vegan"),
        "Gluten-Free": (type: "health", value: "gluten-free"),
        "Dairy-Free": (type: "health", value: "dairy-free"),
        "Nut-Free": (type: "health", value: "peanut-free"),
        "Low-Carb": (type: "diet", value: "low-carb"),
        "Low-Fat": (type: "diet", value: "low-fat"),
        "High-Protein": (type: "diet", value: "high-protein"),
        "High-Fiber": (type: "diet", value: "high-fiber"),
        "Low-Sodium": (type: "diet", value: "low-sodium")
    ]
    
    func searchRecipes(
        query: String,
        mealType: String? = nil,
        dietaryRestrictions: [String] = [],
        maxCalories: Int? = nil
    ) async throws -> [APIRecipe] {
        isLoading = true
        error = nil
        
        do {
            let recipes = try await fetchRecipes(query: query, mealType: mealType, dietaryRestrictions: dietaryRestrictions, maxCalories: maxCalories)
            searchResults = recipes
            isLoading = false
            return recipes
        } catch let recipeError as RecipeError {
            error = recipeError
            isLoading = false
            throw recipeError
        } catch {
            let recipeError = RecipeError.decodingError
            self.error = recipeError
            isLoading = false
            throw recipeError
        }
    }

    func getRecipes(query: String, mealType: String? = nil, dietaryRestrictions: [String] = [], maxCalories: Int? = nil) {
        isLoading = true
        error = nil
        
        Task {
            do {
                let recipes = try await fetchRecipes(query: query, mealType: mealType, dietaryRestrictions: dietaryRestrictions, maxCalories: maxCalories)
                await MainActor.run {
                    self.searchResults = recipes
                    self.isLoading = false
                }
            } catch let recipeError as RecipeError {
                await MainActor.run {
                    self.error = recipeError
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = RecipeError.decodingError
                    self.isLoading = false
                }
            }
        }
    }
    
    private func fetchRecipes(
        query: String,
        mealType: String? = nil,
        dietaryRestrictions: [String] = [],
        maxCalories: Int? = nil
    ) async throws -> [APIRecipe] {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "type", value: "public"),
            URLQueryItem(name: "app_id", value: appId),
            URLQueryItem(name: "app_key", value: appKey)
        ]
        
        if !query.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "q", value: query))
        }
        
        if let mealType = mealType {
            components.queryItems?.append(URLQueryItem(name: "mealType", value: mealType.lowercased()))
        }
        
        var healthParams: Set<String> = []
        var dietParams: Set<String> = []
        
        for restriction in dietaryRestrictions {
            if let mapping = dietMapping[restriction] {
                switch mapping.type {
                case "health":
                    healthParams.insert(mapping.value)
                case "diet":
                    dietParams.insert(mapping.value)
                default:
                    break
                }
            }
        }
        
        for healthParam in healthParams {
            components.queryItems?.append(URLQueryItem(name: "health", value: healthParam))
        }
        
        for dietParam in dietParams {
            components.queryItems?.append(URLQueryItem(name: "diet", value: dietParam))
        }
        
        if let maxCalories = maxCalories {
            components.queryItems?.append(URLQueryItem(name: "calories", value: "0-\(maxCalories)"))
        }
        
        components.queryItems?.append(URLQueryItem(name: "random", value: "true"))
        
        guard let url = components.url else {
            throw RecipeError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("0", forHTTPHeaderField: "Edamam-Account-User")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RecipeError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw RecipeError.invalidResponse
        }
        
        guard !data.isEmpty else {
            throw RecipeError.noData
        }
        
        do {
            let decoder = JSONDecoder()
            let searchResponse = try decoder.decode(RecipeSearchResponse.self, from: data)
            
            guard !searchResponse.hits.isEmpty else {
                throw RecipeError.noResults
            }
            
            return searchResponse.hits.map { $0.recipe }
        } catch {
            print("Decoding error: \(error)")
            throw RecipeError.decodingError
        }
    }
} 
