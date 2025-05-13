//
//  RecipeCart.swift
//  Meal Planner and Recipe Finder
//
//  Created by Ayush Wattamwar on 3/27/25.
//

import SwiftUI

struct RecipeCard: View {
    let recipe: Recipe
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
               
                AsyncImage(url: URL(string: recipe.image)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_):
                        recipePlaceholder
                    case .empty:
                        ProgressView()
                    @unknown default: 
                        recipePlaceholder
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(.rect(cornerRadius: 8))
                
                // Recipe Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.label)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Label(
                        title: { Text(recipe.formattedCalories + " calories") },
                        icon: { Image(systemName: "flame") }
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
                    if !recipe.mealType.isEmpty {
                        Label(
                            title: { Text(recipe.mealType.joined(separator: ", ").capitalized) },
                            icon: { Image(systemName: "clock") }
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                
                Spacer(minLength: 0)
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .fontWeight(.semibold)
            }
            .padding()
            .background(.background.shadow(.drop(radius: 2)))
            .clipShape(.rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .contentShape(.rect)
    }
    
    private var recipePlaceholder: some View {
        Image(systemName: "fork.knife") 
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.secondary.opacity(0.1))
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            RecipeCard(recipe: Recipe.preview) {}
            RecipeCard(recipe: Recipe.preview) {}
        }
        .padding()
    }
} 
