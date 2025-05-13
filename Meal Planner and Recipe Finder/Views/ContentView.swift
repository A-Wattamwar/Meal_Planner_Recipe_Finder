//
//  ContentView.swift
//  Meal Planner and Recipe Finder
//
//  Created by Ayush Wattamwar on 3/27/25.
//

import SwiftUI
import SwiftData 

struct ThemeKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isDarkMode: Bool {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

struct ContentView: View {
    
    let recipeService: RecipeService
    @ObservedObject var recipesVM: RecipesViewModel 
    @State private var createMealVM: CreateMealViewModel
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @State private var showingOnboarding = false
    @State private var isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
    
    init(recipeService: RecipeService, recipesVM: RecipesViewModel) {
        self.recipeService = recipeService
        self.recipesVM = recipesVM
        self._createMealVM = State(initialValue: CreateMealViewModel(recipeService: recipeService))
    }
    
    var body: some View {
        Group {
            if userProfiles.isEmpty {
                OnboardingView(onComplete: handleOnboardingComplete(_:))
            } else {
                mainTabView
                    .onAppear {
                        createMealVM.setModelContext(modelContext)
                        recipesVM.setModelContext(modelContext)
                    }
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .environment(\.isDarkMode, isDarkMode)
        .onAppear { showingOnboarding = userProfiles.isEmpty }
        .onChange(of: isDarkMode) { _, newValue in
            UserDefaults.standard.set(newValue, forKey: "isDarkMode")
        }
    }

    var mainTabView: some View {
        TabView {
            HomeView(recipesVM: recipesVM)
                .tabItem { Label("Home", systemImage: "house.fill") }
            CreateMealView(viewModel: createMealVM, recipesVM: recipesVM)
                .tabItem { Label("Create", systemImage: "plus.circle.fill") }
            MapView()
                .tabItem { Label("Map", systemImage: "location.fill") }
            ProfileView(isDarkMode: $isDarkMode)
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
    }

    func handleOnboardingComplete(_ newProfile: UserProfile) {
        modelContext.insert(newProfile)
        showingOnboarding = false
    }
}

struct OnboardingView: View {

    var onComplete: (UserProfile) -> Void

    @State private var currentStep = 0
    @State private var name = ""
    @State private var email = ""
    @State private var dailyCalorieGoal = ""
    @State private var selectedDietaryRestrictions = Set<String>()
    @State private var selectedHealthGoals = Set<String>()

    let dietaryOptions = ["Vegetarian", "Vegan", "Gluten‑Free", "Dairy‑Free", "Nut‑Free"]
    let healthGoalOptions = ["Weight Management", "Muscle Gain", "Heart Health", "Energy Boost"]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.purple.opacity(0.8)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                VStack(spacing: 0) {
                    header(geometry.safeAreaInsets.top)
                    card
                    footer(geometry.safeAreaInsets.bottom)
                    Spacer()
                }
            }
        }
    }

    func header(_ topInset: CGFloat) -> some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "fork.knife").font(.system(size: 30)).foregroundColor(.white)
                Text("Meal Planner").font(.title).fontWeight(.bold).foregroundColor(.white)
            }
            HStack(spacing: 15) {
                ForEach(0..<3) { step in
                    Circle()
                        .fill(step == currentStep ? .white : .white.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
            }
            .padding(.top, 10)
        }
        .padding(.top, topInset + 30)
    }

    var card: some View {
        VStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                .overlay(
                    VStack {
                        if currentStep == 0 { personalInfoStep }
                        else if currentStep == 1 { dietaryRestrictionsStep }
                        else { healthGoalsStep }
                    }
                    .padding(24)
                )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }

    func footer(_ bottomInset: CGFloat) -> some View {
        HStack {
            if currentStep > 0 { buttonBack }
            buttonNext
        }
        .padding(.horizontal, 20)
        .padding(.top, 15)
        .padding(.bottom, bottomInset + 40)
    }

    var buttonBack: some View {
        Button {
            withAnimation { currentStep -= 1 }
        } label: {
            HStack { Image(systemName: "arrow.left"); Text("Back") }
                .font(.headline)
                .foregroundColor(.white)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.trailing, 8)
    }

    var buttonNext: some View {
        Button {
            if currentStep < 2 { withAnimation { currentStep += 1 } }
            else { createProfile() }
        } label: {
            HStack {
                Text(currentStep == 2 ? "Get Started" : "Next")
                Image(systemName: "arrow.right")
            }
            .font(.headline)
            .foregroundColor(.blue)
            .frame(height: 50)
            .frame(maxWidth: currentStep > 0 ? .infinity : nil, alignment: .center)
            .padding(.horizontal, currentStep > 0 ? 0 : 40)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 3)
        }
        .disabled(currentStep == 0 && (name.isEmpty || email.isEmpty))
        .opacity(currentStep == 0 && (name.isEmpty || email.isEmpty) ? 0.5 : 1)
    }

    var personalInfoStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Welcome!").font(.largeTitle).fontWeight(.bold).foregroundColor(.blue)
                Text("Let's personalize your meal planning experience")
                    .font(.subheadline).foregroundColor(.secondary)
            }
            inputField(title: "Your Name", text: $name, placeholder: "Enter your name")
            inputField(title: "Email Address", text: $email, placeholder: "Enter your email", keyboard: .emailAddress)
            calorieField
        }
    }

    func inputField(title: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline).foregroundColor(.primary)
            TextField(placeholder, text: text)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .keyboardType(keyboard)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
    }

    var calorieField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Daily Calorie Goal").font(.headline).foregroundColor(.primary)
            HStack {
                TextField("Enter calorie goal", text: $dailyCalorieGoal)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .keyboardType(.numberPad)
                    .autocorrectionDisabled()
                Text("calories").foregroundColor(.secondary)
            }
        }
    }

    var dietaryRestrictionsStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            stepHeader(title: "Dietary Preferences", subtitle: "Select any dietary restrictions you follow")
            selectionList(options: dietaryOptions,
                          selected: $selectedDietaryRestrictions,
                          selectedColor: .blue,
                          selectedSymbol: "checkmark.square.fill",
                          unselectedSymbol: "square")
            Spacer().frame(height: 20)
            Text("These preferences will help us suggest recipes suitable for your diet.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    var healthGoalsStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            stepHeader(title: "Health Goals", subtitle: "What are you trying to achieve?")
            selectionList(options: healthGoalOptions,
                          selected: $selectedHealthGoals,
                          selectedColor: .green,
                          selectedSymbol: "checkmark.circle.fill",
                          unselectedSymbol: "circle")
            Spacer().frame(height: 20)
            benefitIcons
        }
    }

    func stepHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.largeTitle).fontWeight(.bold).foregroundColor(.blue)
            Text(subtitle).font(.subheadline).foregroundColor(.secondary)
        }
    }

    func selectionList(options: [String], selected: Binding<Set<String>>, selectedColor: Color, selectedSymbol: String, unselectedSymbol: String) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    HStack {
                        Image(systemName: selected.wrappedValue.contains(option) ? selectedSymbol : unselectedSymbol)
                            .font(.title2)
                        Text(option).font(.headline).padding(.leading, 8)
                        Spacer()
                    }
                    .foregroundColor(selected.wrappedValue.contains(option) ? selectedColor : .gray)
                    .contentShape(Rectangle())
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selected.wrappedValue.contains(option) ? selectedColor.opacity(0.1) : Color.gray.opacity(0.05))
                    )
                    .onTapGesture {
                        if selected.wrappedValue.contains(option) {
                            selected.wrappedValue.remove(option)
                        } else {
                            selected.wrappedValue.insert(option)
                        }
                    }
                }
            }
        }
    }

    var benefitIcons: some View {
        HStack(spacing: 20) {
            benefitIcon(symbol: "list.bullet.clipboard", label: "Personalized")
            benefitIcon(symbol: "fork.knife", label: "Easy Recipes")
            benefitIcon(symbol: "chart.line.uptrend.xyaxis", label: "Track Progress")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }

    func benefitIcon(symbol: String, label: String) -> some View {
        VStack {
            Image(systemName: symbol).font(.largeTitle).foregroundColor(.blue)
            Text(label).font(.caption).foregroundColor(.secondary)
        }
    }

    func createProfile() {
        let profile = UserProfile(
            name: name,
            email: email,
            dailyCalorieGoal: Int(dailyCalorieGoal) ?? 2000,
            dietaryRestrictions: selectedDietaryRestrictions,
            healthGoals: Array(selectedHealthGoals)
        )
        onComplete(profile)
    }
}

#Preview {
    let recipeService = RecipeService(appId: "0a7189c7", appKey: "9d11e54ebbfc928900f654db1e5f908f")
    let recipesVM = RecipesViewModel(recipeService: recipeService)
    return ContentView(recipeService: recipeService, recipesVM: recipesVM)
        .modelContainer(
            for: [
        Recipe.self,
        Ingredient.self,
        NutrientsInfo.self,
        Nutrient.self,
        Restaurant.self,
        UserProfile.self
            ],
            inMemory: true
        )
}
