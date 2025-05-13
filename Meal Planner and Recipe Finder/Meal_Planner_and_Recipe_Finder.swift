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
    // Edamam API credentials from Info.plist
    private let recipeService: RecipeService
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
        // Get API keys from Info.plist
        guard let infoDict = Bundle.main.infoDictionary,
              let appId = infoDict["EDAMAM_APP_ID"] as? String,
              let appKey = infoDict["EDAMAM_APP_KEY"] as? String else {
            fatalError("API credentials not found in Info.plist")
        }
        
        // Initialize the service with keys from config
        let service = RecipeService(appId: appId, appKey: appKey)
        self.recipeService = service
        
        let viewModel = RecipesViewModel(recipeService: service) 
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
