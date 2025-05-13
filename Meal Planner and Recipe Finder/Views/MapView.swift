//
//  MapView.swift
//  Meal Planner and Recipe Finder
//
//  Created by Ayush Wattamwar on 3/29/25.
//

import SwiftUI
import MapKit
import SwiftData

@Model
final class Restaurant {
    @Attribute(.unique) var id: UUID
    var name: String
    var cuisine: String
    var rating: Double
    var latitude: Double
    var longitude: Double
    var address: String
    var dietaryOptions: [String]
    var isFavorite: Bool
    var dateAdded: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var formattedRating: String {
        String(format: "%.1f", rating)
    }

    init(
        id: UUID = UUID(),
        name: String,
        cuisine: String,
        rating: Double,
        coordinate: CLLocationCoordinate2D,
        address: String = "",
        dietaryOptions: [String] = [],
        isFavorite: Bool = false,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.cuisine = cuisine
        self.rating = rating
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.address = address
        self.dietaryOptions = dietaryOptions
        self.isFavorite = isFavorite
        self.dateAdded = dateAdded
    }
}

struct MapView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var restaurants: [Restaurant]
    @State private var showAddSheet = false
    @State private var selectedRestaurant: Restaurant? = nil
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 33.4255, longitude: -111.9400),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    private var sampleRestaurants: [Restaurant] {
        return [
            // Preloaded restaurants
            Restaurant(
                name: "Culinary Dropout",
                cuisine: "American",
                rating: 4.5,
                coordinate: CLLocationCoordinate2D(latitude: 33.4280, longitude: -111.9307),
                address: "149 S Farmer Ave, Tempe, AZ 85281",
                dietaryOptions: ["Gluten-Free", "Vegetarian"]
            ),
            Restaurant(
                name: "House of Tricks",
                cuisine: "New American",
                rating: 4.7,
                coordinate: CLLocationCoordinate2D(latitude: 33.4251, longitude: -111.9360),
                address: "114 E 7th St, Tempe, AZ 85281",
                dietaryOptions: ["Vegetarian", "Vegan"]
            ),
            Restaurant(
                name: "Four Peaks Brewing Company",
                cuisine: "Brewery",
                rating: 4.6,
                coordinate: CLLocationCoordinate2D(latitude: 33.4203, longitude: -111.9097),
                address: "1340 E 8th St #104, Tempe, AZ 85281",
                dietaryOptions: ["Gluten-Free"]
            ),
            Restaurant(
                name: "Ghost Ranch",
                cuisine: "Southwestern",
                rating: 4.4,
                coordinate: CLLocationCoordinate2D(latitude: 33.3831, longitude: -111.9562),
                address: "1006 E Warner Rd #102-103, Tempe, AZ 85284",
                dietaryOptions: ["Vegetarian", "Gluten-Free"]
            )
        ]
    }

    private func initializeSampleDataIfNeeded() {
        if restaurants.isEmpty, !sampleRestaurants.isEmpty {
            for restaurant in sampleRestaurants {
                modelContext.insert(restaurant)
            }
            try? modelContext.save()
        }
    }
    
    private func saveRestaurant(_ restaurant: Restaurant) {
        // if already exists, don't save
        let existingRestaurants = restaurants.filter { 
            $0.name == restaurant.name && 
            abs($0.latitude - restaurant.latitude) < 0.0001 && 
            abs($0.longitude - restaurant.longitude) < 0.0001
        }
        
        if existingRestaurants.isEmpty {
            modelContext.insert(restaurant)
            try? modelContext.save()
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ZStack(alignment: .bottomTrailing) {
                    MapView_UIKit(
                        region: $region,
                        restaurants: restaurants,
                        selectedRestaurant: $selectedRestaurant
                    )
                    // Add button placed on map
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .padding()
                }
                .frame(height: UIScreen.main.bounds.height * 0.4)
                
                if restaurants.isEmpty {
                    ContentUnavailableView {
                        Label("No Restaurants", systemImage: "mappin.slash")
                    } description: {
                        Text("Add restaurants using the + button")
                    }
                } else {
                    List {
                        ForEach(restaurants) { restaurant in
                            RestaurantListItem(restaurant: restaurant, isSelected: selectedRestaurant?.id == restaurant.id) { action in
                                switch action {
                                case .view:
                                    selectedRestaurant = restaurant
                                case .highlight:
                                    region.center = restaurant.coordinate
                                    region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Nearby Restaurants")
            .sheet(isPresented: $showAddSheet) {
                AddRestaurantView(onSave: { restaurant in
                    saveRestaurant(restaurant)
                    showAddSheet = false
                })
            }
            .sheet(item: $selectedRestaurant) { restaurant in
                RestaurantDetailView(restaurant: restaurant, onDismiss: {
                    selectedRestaurant = nil
                })
            }
            .onAppear {
                initializeSampleDataIfNeeded()
            }
        }
    }
}

extension MKLocalSearch {
    static func searchLocations(query: String, in region: MKCoordinateRegion, completion: @escaping ([MKMapItem]) -> Void) {
        guard !query.isEmpty else {
            completion([])
            return
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let error = error {
                print("Search error: \(error.localizedDescription)")
                completion([])
                return
            }
            
            if let items = response?.mapItems {
                completion(items)
            } else {
                completion([])
            }
        }
    }
}

struct MapView_UIKit: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var restaurants: [Restaurant]
    @Binding var selectedRestaurant: Restaurant?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.setRegion(region, animated: true)
        updateAnnotations(mapView: mapView)
    }
    
    private func updateAnnotations(mapView: MKMapView) {
        let annotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(annotations)
        
        for restaurant in restaurants {
            let annotation = RestaurantAnnotation(restaurant: restaurant)
            mapView.addAnnotation(annotation)
        }
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView_UIKit
        
        init(_ parent: MapView_UIKit) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
            if let restaurantAnnotation = annotation as? RestaurantAnnotation {
                parent.selectedRestaurant = restaurantAnnotation.restaurant
            }
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil
            }
            
            if let restaurantAnnotation = annotation as? RestaurantAnnotation {
                let identifier = "RestaurantMarker"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                
                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                    let infoButton = UIButton(type: .detailDisclosure)
                    annotationView?.rightCalloutAccessoryView = infoButton
                } else {
                    annotationView?.annotation = annotation
                }
                
                annotationView?.markerTintColor = restaurantAnnotation.restaurant.isFavorite ? .systemPink : .systemBlue
                annotationView?.glyphImage = UIImage(systemName: "fork.knife")
                
                return annotationView
            }
            
            return nil
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            if let restaurantAnnotation = view.annotation as? RestaurantAnnotation {
                parent.selectedRestaurant = restaurantAnnotation.restaurant
            }
        }
    }
}

class RestaurantAnnotation: NSObject, MKAnnotation {
    let restaurant: Restaurant
    var coordinate: CLLocationCoordinate2D { restaurant.coordinate }
    var title: String? { restaurant.name }
    var subtitle: String? { restaurant.cuisine }
    
    init(restaurant: Restaurant) {
        self.restaurant = restaurant
        super.init()
    }
}

enum RestaurantAction {
    case view
    case highlight
}

struct RestaurantListItem: View {
    let restaurant: Restaurant
    let isSelected: Bool
    let onAction: (RestaurantAction) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Restaurant info
            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(.headline)
                    .lineLimit(1)
                
                if !restaurant.cuisine.isEmpty {
                    Text(restaurant.cuisine)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 2) {
                    Label(
                        title: { Text(restaurant.formattedRating) },
                        icon: { Image(systemName: "star.fill").foregroundStyle(.yellow) }
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    
                    if restaurant.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                            .padding(.leading, 4)
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onAction(.highlight)
            }
            
            Spacer()
            
            Button {
                onAction(.view)
            } label: {
                Image(systemName: "info.circle")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
        .listRowBackground(isSelected ? Color.blue.opacity(0.1) : nil)
    }
}

struct RestaurantDetailView: View {
    let restaurant: Restaurant
    var onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var isEditing = false
    @State private var isFavorite: Bool
    @State private var editedCuisine: String
    @State private var dietaryOptions: [String]
    @State private var showDeleteAlert = false
    
    private let availableDietaryOptions = ["Vegetarian", "Vegan", "Gluten-Free", "Dairy-Free", "Nut-Free"]
    
    init(restaurant: Restaurant, onDismiss: @escaping () -> Void = {}) {
        self.restaurant = restaurant
        self.onDismiss = onDismiss
        self._isFavorite = State(initialValue: restaurant.isFavorite)
        self._editedCuisine = State(initialValue: restaurant.cuisine)
        self._dietaryOptions = State(initialValue: restaurant.dietaryOptions)
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Restaurant Info
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(restaurant.name)
                            .font(.title2)
                            .bold()
                        
                        if isEditing {
                            TextField("Cuisine", text: $editedCuisine)
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .padding(.vertical, 4)
                        } else if !restaurant.cuisine.isEmpty {
                            Text(restaurant.cuisine)
                                .foregroundStyle(.secondary)
                        }
                        
                        if !restaurant.address.isEmpty {
                            Text(restaurant.address)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Label(
                                title: { Text(restaurant.formattedRating) },
                                icon: { Image(systemName: "star.fill") }
                            )
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        }
                    }
                }
                
                // Dietary Options
                Section("Dietary Options") {
                    if isEditing {
                        ForEach(availableDietaryOptions, id: \.self) { option in
                            Toggle(option, isOn: Binding(
                                get: { dietaryOptions.contains(option) },
                                set: { isOn in
                                    if isOn {
                                        if !dietaryOptions.contains(option) {
                                            dietaryOptions.append(option)
                                        }
                                    } else {
                                        dietaryOptions.removeAll { $0 == option }
                                    }
                                }
                            ))
                        }
                    } else if !restaurant.dietaryOptions.isEmpty {
                        ForEach(restaurant.dietaryOptions, id: \.self) { option in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text(option)
                            }
                        }
                    } else {
                        Text("No dietary options specified")
                            .foregroundStyle(.secondary)
                            .italic()
                    }
                }
                
                Section {
                    Button {
                        let coordinate = restaurant.coordinate
                        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
                        mapItem.name = restaurant.name
                        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
                    } label: {
                        Label("Get Directions", systemImage: "arrow.turn.up.right")
                    }
                    
                    Button {
                        isFavorite.toggle()
                        restaurant.isFavorite = isFavorite
                        try? modelContext.save()
                    } label: {
                        Label(
                            isFavorite ? "Remove from Favorites" : "Add to Favorites",
                            systemImage: isFavorite ? "heart.fill" : "heart"
                        )
                        .foregroundStyle(isFavorite ? .red : .primary)
                    }
                }
            }
            .navigationTitle("Restaurant Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { 
                        dismiss()
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if isEditing {
                        Button("Save") {
                            restaurant.cuisine = editedCuisine
                            restaurant.dietaryOptions = dietaryOptions
                            try? modelContext.save()
                            isEditing = false
                        }
                    } else {
                        Button("Edit") {
                            isEditing = true
                        }
                    }
                }

                ToolbarItem(placement: .bottomBar) {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .alert("Delete Restaurant?", isPresented: $showDeleteAlert, actions: {
                Button("Delete", role: .destructive) {
                    modelContext.delete(restaurant)
                    try? modelContext.save()
                    dismiss()
                    onDismiss()
                }
                Button("Cancel", role: .cancel) {}
            }, message: {
                Text("This action cannot be undone.")
            })
        }
    }
}

struct AddRestaurantView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var selectedMapItem: MKMapItem? = nil
    @State private var selectedRestaurant: Restaurant? = nil
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 33.4255, longitude: -111.9400), // Tempe, AZ
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var onSave: (Restaurant) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search for restaurants", text: $searchText)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .submitLabel(.search)
                        .onSubmit { performSearch() }
                    
                    if !searchText.isEmpty {
                        Button(action: { 
                            searchText = ""
                            searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
                if isSearching {
                    ProgressView("Searching...")
                        .padding()
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    ContentUnavailableView("No Results", systemImage: "magnifyingglass", description: Text("Try a different search term"))
                } else if !searchResults.isEmpty {
                    List {
                        ForEach(searchResults, id: \.self) { item in
                            SearchResultRow(item: item) { selectedItem in
                                selectedMapItem = selectedItem
                                let restaurant = restaurantFromMapItem(selectedItem)
                                selectedRestaurant = restaurant
                            }
                        }
                    }
                    .listStyle(.plain)
                } else {
                    ContentUnavailableView("Search Places", systemImage: "mappin.and.ellipse", description: Text("Type above to search for restaurants and places"))
                }
            }
            .navigationTitle("Add Restaurant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if let restaurant = selectedRestaurant {
                        Button("Save") { onSave(restaurant) }
                    }
                }
            }
            .sheet(item: $selectedRestaurant) { restaurant in
                NavigationStack {
                    RestaurantDetailPreview(restaurant: restaurant) { updatedRestaurant in
                        self.selectedRestaurant = updatedRestaurant
                    }
                    .navigationTitle("Preview")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { 
                                if let restaurant = selectedRestaurant {
                                    onSave(restaurant)
                                }
                            }
                        }
                        
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") { 
                                selectedRestaurant = nil
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        MKLocalSearch.searchLocations(query: searchText, in: region) { items in
            isSearching = false
            searchResults = items
        }
    }
    
    private func restaurantFromMapItem(_ item: MKMapItem) -> Restaurant {
        let coordinate = item.placemark.coordinate
        let address = [item.placemark.thoroughfare, item.placemark.locality, item.placemark.administrativeArea, item.placemark.postalCode]
            .compactMap { $0 }
            .joined(separator: ", ")
        
        // Determine cuisine based on category
        let cuisine: String
        if let category = item.pointOfInterestCategory?.rawValue {
            switch category {
            case "MKPOICategoryRestaurant":
                cuisine = "Restaurant"
            case "MKPOICategoryBakery":
                cuisine = "Bakery"
            case "MKPOICategoryCafe":
                cuisine = "Cafe"
            case "MKPOICategoryFoodMarket":
                cuisine = "Food Market"
            case "MKPOICategoryWinery":
                cuisine = "Winery"
            default:
                cuisine = ""
            }
        } else {
            cuisine = ""
        }
        
        return Restaurant(
            name: item.name ?? "Unknown Place",
            cuisine: cuisine,
            rating: 4.0,
            coordinate: coordinate,
            address: address,
            dietaryOptions: [],
            isFavorite: false,
            dateAdded: Date()
        )
    }
}

struct SearchResultRow: View {
    let item: MKMapItem
    let onSelect: (MKMapItem) -> Void
    
    var body: some View {
        Button {
            onSelect(item)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name ?? "Unknown Place")
                        .font(.headline)
                    
                    if let address = item.placemark.thoroughfare {
                        Text(address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
    }
}

struct RestaurantDetailPreview: View {
    @State var restaurant: Restaurant
    var onUpdate: (Restaurant) -> Void
    
    var body: some View {
        Form {
            Section("Restaurant Information") {
                TextField("Name", text: $restaurant.name)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onChange(of: restaurant) { onUpdate(restaurant) }
                
                TextField("Cuisine", text: $restaurant.cuisine)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onChange(of: restaurant) { onUpdate(restaurant) }
                
                TextField("Address", text: $restaurant.address)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onChange(of: restaurant) { onUpdate(restaurant) }
                
                HStack {
                    Text("Rating")
                    Spacer()
                    ForEach(1...5, id: \.self) { rating in
                        Image(systemName: rating <= Int(restaurant.rating) ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .onTapGesture {
                                restaurant.rating = Double(rating)
                                onUpdate(restaurant)
                            }
                    }
                }
            }
            
            Section("Dietary Options") {
                Toggle("Vegetarian", isOn: Binding(
                    get: { restaurant.dietaryOptions.contains("Vegetarian") },
                    set: { newValue in
                        updateDietaryOption("Vegetarian", isSelected: newValue)
                    }
                ))
                
                Toggle("Vegan", isOn: Binding(
                    get: { restaurant.dietaryOptions.contains("Vegan") },
                    set: { newValue in
                        updateDietaryOption("Vegan", isSelected: newValue)
                    }
                ))
                
                Toggle("Gluten-Free", isOn: Binding(
                    get: { restaurant.dietaryOptions.contains("Gluten-Free") },
                    set: { newValue in
                        updateDietaryOption("Gluten-Free", isSelected: newValue)
                    }
                ))
                
                Toggle("Dairy-Free", isOn: Binding(
                    get: { restaurant.dietaryOptions.contains("Dairy-Free") },
                    set: { newValue in
                        updateDietaryOption("Dairy-Free", isSelected: newValue)
                    }
                ))
            }
        }
    }
    
    private func updateDietaryOption(_ option: String, isSelected: Bool) {
        if isSelected {
            if !restaurant.dietaryOptions.contains(option) {
                restaurant.dietaryOptions.append(option)
            }
        } else {
            restaurant.dietaryOptions.removeAll { $0 == option }
        }
        onUpdate(restaurant)
    }
}

#Preview {
    MapView()
}
