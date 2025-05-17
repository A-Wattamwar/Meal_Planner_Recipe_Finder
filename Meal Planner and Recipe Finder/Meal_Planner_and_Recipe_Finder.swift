//
//  Meal_Planner_and_Recipe_FinderApp.swift
//  Meal Planner and Recipe Finder
//
//  Created by Ayush Wattamwar on 3/27/25.
//

import SwiftUI
import SwiftData 

@main
struct Meal_Planner_and_Recipe_Finder: App { 
    // Using RecipeService with credentials from Credentials.swift
    private let recipeService = RecipeService()
    @StateObject private var recipesVM: RecipesViewModel
    @Environment(\.scenePhase) private var scenePhase
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Recipe.self,
            Ingredient.self,
            NutrientsInfo.self,
            Nutrient.self,
            UserProfile.self,
            Restaurant.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("Created ModelContainer successfully")
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        let viewModel = RecipesViewModel(recipeService: recipeService) 
        _recipesVM = StateObject(wrappedValue: viewModel)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(recipeService: recipeService, recipesVM: recipesVM)
                .modelContainer(sharedModelContainer)
                .onAppear {
                    let context = sharedModelContainer.mainContext
                    recipesVM.setModelContext(context)
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .inactive {
                try? sharedModelContainer.mainContext.save()
            }
        }
    }
}
