//
//  CommonViews.swift
//  Meal Planner and Recipe Finder
//
//  Created by Ayush Wattamwar on 3/27/25.
//

import SwiftUI

struct ContentLoadingView: View { 
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
            Text("Finding recipes...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

struct ContentErrorView: View {
    let message: String
    let retryAction: (() -> Void)?
    
    init(message: String, retryAction: (() -> Void)? = nil) {
        self.message = message
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.red)
            Text(message)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
            
            if let retryAction {
                Button(action: retryAction) {
                    Label("Try Again", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}

struct RecipeResultsView: View {
    let recipes: [Recipe]
    let onRecipeSelected: (Recipe) -> Void
    
    var body: some View {
        if recipes.isEmpty {
            ContentUnavailableView {
                Label("No Recipes Found", systemImage: "fork.knife")
            } description: {
                Text("Try adjusting your search criteria")
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(recipes) { recipe in
                        RecipeCard(recipe: recipe) {
                            onRecipeSelected(recipe)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
    }
}

#Preview("Loading") {
    ContentLoadingView()
}

#Preview("Error") {
    ContentErrorView(message: "Something went wrong", retryAction: {})
}

#Preview("Results") {
    RecipeResultsView(recipes: [Recipe.preview]) { _ in }
}  
