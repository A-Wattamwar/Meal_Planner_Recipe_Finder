//
//  ProfileView.swift
//  Meal Planner and Recipe Finder
//
//  Created by Ayush Wattamwar on 3/29/25.
//

import SwiftUI
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id = UUID()
    var name: String
    var email: String
    var dailyCalorieGoal: Int
    var dietaryRestrictions: Set<String>
    var healthGoals: [String]
    
    init(name: String, email: String, dailyCalorieGoal: Int, dietaryRestrictions: Set<String>, healthGoals: [String]) {
        self.name = name
        self.email = email
        self.dailyCalorieGoal = dailyCalorieGoal
        self.dietaryRestrictions = dietaryRestrictions
        self.healthGoals = healthGoals
    }
}

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    @Binding var isDarkMode: Bool
    
    init(isDarkMode: Binding<Bool> = .constant(false)) {
        self._isDarkMode = isDarkMode
    }
    
    var body: some View {
        NavigationView {
            if userProfiles.isEmpty {
                ContentUnavailableView {
                    Label("No Profile", systemImage: "person.crop.circle.badge.exclamationmark")
                } description: {
                    Text("Your profile information will appear here")
                } actions: {
                    Button("Create Profile") {
                        let defaultProfile = UserProfile(
                            name: "New User",
                            email: "user@example.com",
                            dailyCalorieGoal: 2000,
                            dietaryRestrictions: [],
                            healthGoals: []
                        )
                        modelContext.insert(defaultProfile)
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                profileContent
            }
        }
    }
    
    private var userProfile: UserProfile {
        userProfiles.first!
    }
    
    private var profileContent: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                            .padding(.bottom, 8)
                        
                        Text(userProfile.name)
                            .font(.title2)
                            .bold()
                        
                        Text(userProfile.email)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
            
            Section {
                ForEach(userProfile.healthGoals, id: \.self) { goal in
                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(.green)
                            .font(.headline)
                        Text(goal)
                            .font(.body)
                        Spacer()
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                HStack {
                    Image(systemName: "bolt.heart")
                        .foregroundColor(.green)
                    Text("Health Goals")
                        .font(.headline)
                }
            }
            
            Section {
                ForEach(Array(userProfile.dietaryRestrictions), id: \.self) { restriction in
                    HStack {
                        Image(systemName: "leaf")
                            .foregroundColor(.blue)
                            .font(.headline)
                        Text(restriction)
                            .font(.body)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                HStack {
                    Image(systemName: "fork.knife")
                        .foregroundColor(.blue)
                    Text("Dietary Restrictions")
                        .font(.headline)
                }
            }
            
            Section {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.title3)
                    Text("\(userProfile.dailyCalorieGoal)")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.orange)
                    Text("calories per day")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            } header: {
                HStack {
                    Image(systemName: "chart.bar")
                        .foregroundColor(.orange)
                    Text("Daily Calorie Goal")
                        .font(.headline)
                }
            }
        
            Section {
                Button(action: {
                    showingEditProfile = true
                }) {
                    HStack {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                            .font(.headline)
                        Text("Edit Profile")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                }
                
                Button(action: {
                    showingSettings = true
                }) {
                    HStack {
                        Image(systemName: "gear")
                            .foregroundColor(.gray)
                            .font(.headline)
                        Text("Settings")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Profile")
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(userProfile: userProfile)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(isDarkMode: $isDarkMode)
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}

struct EditProfileView: View {
    var userProfile: UserProfile
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name: String
    @State private var email: String
    @State private var dailyCalorieGoal: String
    @State private var selectedDietaryRestrictions: Set<String>
    @State private var selectedHealthGoals: Set<String>
    
    let dietaryOptions = ["Vegetarian", "Vegan", "Gluten-Free", "Dairy-Free", "Nut-Free"]
    let healthGoalOptions = ["Weight Management", "Muscle Gain", "Heart Health", "Energy Boost"]
    
    init(userProfile: UserProfile) {
        self.userProfile = userProfile
        self._name = State(initialValue: userProfile.name)
        self._email = State(initialValue: userProfile.email)
        self._dailyCalorieGoal = State(initialValue: String(userProfile.dailyCalorieGoal))
        self._selectedDietaryRestrictions = State(initialValue: userProfile.dietaryRestrictions)
        self._selectedHealthGoals = State(initialValue: Set(userProfile.healthGoals))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Name", text: $name)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    TextField("Daily Calorie Goal", text: $dailyCalorieGoal)
                        .keyboardType(.numberPad)
                        .autocorrectionDisabled()
                }
                
                Section(header: Text("Dietary Restrictions")) {
                    ForEach(dietaryOptions, id: \.self) { option in
                        Toggle(option, isOn: Binding(
                            get: { selectedDietaryRestrictions.contains(option) },
                            set: { isSelected in
                                if isSelected {
                                    selectedDietaryRestrictions.insert(option)
                                } else {
                                    selectedDietaryRestrictions.remove(option)
                                }
                            }
                        ))
                    }
                }
                
                Section(header: Text("Health Goals")) {
                    ForEach(healthGoalOptions, id: \.self) { option in
                        Toggle(option, isOn: Binding(
                            get: { selectedHealthGoals.contains(option) },
                            set: { isSelected in
                                if isSelected {
                                    selectedHealthGoals.insert(option)
                                } else {
                                    selectedHealthGoals.remove(option)
                                }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    userProfile.name = name
                    userProfile.email = email
                    userProfile.dailyCalorieGoal = Int(dailyCalorieGoal) ?? 2000
                    userProfile.dietaryRestrictions = selectedDietaryRestrictions
                    userProfile.healthGoals = Array(selectedHealthGoals)
                    dismiss()
                }
            )
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @State private var showSignOutAlert = false
    @Binding var isDarkMode: Bool
    
    var body: some View {
        NavigationView { 
            Form {
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $isDarkMode)
                }
                
                Section(header: Text("Account")) {
                    Button(action: {
                        showSignOutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                                .font(.headline)
                            Text("Sign Out")
                                .foregroundColor(.red)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
            } message: {
                Text("Are you sure you want to sign out? This will reset the app.")
            }
        }
    }
    
    private func signOut() {
        for profile in userProfiles {
            modelContext.delete(profile)
        }
        
        // Delete all saved recipes
        do {
            let recipeDescriptor = FetchDescriptor<Recipe>()
            let savedRecipes = try modelContext.fetch(recipeDescriptor)
            for recipe in savedRecipes {
                modelContext.delete(recipe)
            }
        } catch {
            print("Error fetching recipes for deletion: \(error)")
        }

        do {
            let ingredientDescriptor = FetchDescriptor<Ingredient>()
            let ingredients = try modelContext.fetch(ingredientDescriptor)
            for ingredient in ingredients {
                modelContext.delete(ingredient)
            }
        } catch {
            print("Error fetching ingredients for deletion: \(error)")
        }
        
        do {
            let nutrientDescriptor = FetchDescriptor<Nutrient>()
            let nutrients = try modelContext.fetch(nutrientDescriptor)
            for nutrient in nutrients {
                modelContext.delete(nutrient)
            }
        } catch {
            print("Error fetching nutrients for deletion: \(error)")
        }
        
        do {
            let nutrientsInfoDescriptor = FetchDescriptor<NutrientsInfo>()
            let nutrientsInfos = try modelContext.fetch(nutrientsInfoDescriptor)
            for nutrientsInfo in nutrientsInfos {
                modelContext.delete(nutrientsInfo)
            }
        } catch {
            print("Error fetching nutrients info for deletion: \(error)")
        }
        
        do {
            let restaurantDescriptor = FetchDescriptor<Restaurant>()
            let restaurants = try modelContext.fetch(restaurantDescriptor)
            for restaurant in restaurants {
                modelContext.delete(restaurant)
            }
        } catch {
            print("Error fetching restaurants for deletion: \(error)")
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving context after sign out: \(error)")
        }
        
        // Reset dark mode
        isDarkMode = false
        UserDefaults.standard.set(false, forKey: "isDarkMode")
        
        dismiss()
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [UserProfile.self], inMemory: true)
}

