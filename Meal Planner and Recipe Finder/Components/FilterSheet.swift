//
//  FilerSheet.swift
//  Meal Planner and Recipe Finder
//
//  Created by Ayush Wattamwar on 3/27/25.
//

import SwiftUI 

struct FilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var mealType: String
    @Binding var calorieTarget: String
    @Binding var selectedDietaryOptions: Set<String>
    let dietaryOptions: [String]
    let mealTypes: [String]
    let onApply: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Meal Type") {
                    Picker("Meal Type", selection: $mealType) {
                        ForEach(mealTypes, id: \.self) { type in
                            Text(type)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Calorie Target") {
                    HStack {
                        TextField("Enter calories", text: $calorieTarget)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                        Text("cal")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Dietary Restrictions") {
                    ForEach(dietaryOptions, id: \.self) { option in
                        Toggle(option, isOn: Binding(
                            get: { selectedDietaryOptions.contains(option) },
                            set: { isSelected in
                                if isSelected {
                                    selectedDietaryOptions.insert(option)
                                } else {
                                    selectedDietaryOptions.remove(option)
                                }
                            }
                        ))
                    }
                }
            } 
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply()
                        dismiss()
                    }
                }
            }
        }
    }
} 
