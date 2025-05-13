# Meal Planner and Recipe Finder

A sophisticated iOS application for discovering, planning, and saving recipes based on dietary preferences, health goals, and personal taste.

## Overview

Meal Planner and Recipe Finder is an intuitive iOS app built with SwiftUI and SwiftData that helps users find recipes, plan meals, discover nearby restaurants, and track their nutritional preferences. The app uses the Edamam Recipe API to provide a vast collection of culinary options tailored to each user.

[Watch Demo Video](https://www.youtube.com/watch?v=IUZKEgo9pQE)

## Authors

- Ayush Sachin Wattamwar
- Hridaya Amol Dande

## Features

### Recipe Search and Discovery
- Search for recipes using keywords, cuisine types, and ingredients
- Filter recipes by meal type (Breakfast, Lunch, Dinner, Snack)
- Apply dietary restrictions (Vegetarian, Vegan, Gluten-Free, etc.)
- Set calorie limits for healthier meal options
- View detailed nutritional information for each recipe

### Personalized User Profiles
- Create a profile with personal details and dietary preferences
- Set daily calorie goals aligned with health objectives
- Select dietary restrictions that are automatically applied to searches
- Choose health goals to guide recipe recommendations

### Meal Planning
- Save favorite recipes for future reference
- Organize recipes by meal type for weekly planning
- Create custom meal plans with selected recipes
- View nutritional summaries of planned meals

### Restaurant Finder
- Discover nearby restaurants on an interactive map
- Filter restaurants by cuisine type and dietary options
- Save favorite dining locations for future reference
- Add new restaurant discoveries to your personal collection
- View restaurant details including ratings, cuisines, and dietary accommodations

### User Interface
- Intuitive tabbed navigation for easy access to all features
- Elegant onboarding process for new users
- Dark mode support for comfortable viewing in any lighting condition
- Responsive design optimized for various iOS devices

## Technical Details

### Architecture
- **SwiftUI Framework**: Modern declarative UI development
- **SwiftData**: Efficient data persistence and management
- **MVVM Design Pattern**: Clear separation of views, models, and business logic
- **Async/Await**: Modern concurrency for smooth user experience

### Application Architecture

#### Models (Data Layer)
- **Recipe**: Stores essential recipe details including a unique ID, name, image URL, ingredients list, nutritional information, cooking time, cuisine type, and save status.
- **UserProfile**: Manages user personal information and preferences in SwiftData, including name, email, daily calorie goals, dietary restrictions, and health goals for personalized meal recommendations.
- **Restaurant**: Contains information about dining establishments including name, customer rating, location coordinates for mapping, and favorite status.

#### ViewModels (Logic Layer)
- **RecipesViewModel**: Manages recipe collection, search operations, and persistence as an ObservableObject. Publishes changes to recipes, loading states, error handling, and search parameters. Provides methods for recipe search, saved status management, and detailed information retrieval.
- **CreateMealViewModel**: Handles meal creation with functionality for recipe discovery based on meal types and dietary requirements. Manages search configurations and results processing, converting API data to SwiftData models.
- **RecipeService**: Functions as the data retrieval layer for the Edamam Recipe API. Manages API authentication, complex query parameter formulation, loading states, and error handling during network operations.

#### Views (UI Layer)
- **ContentView**: Provides tab-based navigation and determines application state by checking for existing user profiles. Displays either onboarding for new users or the main TabView interface, while managing global settings like dark mode.
- **HomeView**: Presents the user's saved recipe collection with integrated search and filtering capabilities by meal type.
- **CreateMealView**: Facilitates meal planning with comprehensive filters for meal types, calorie targets, and dietary restrictions. Manages sheet presentations for search results and detailed recipe views.
- **ProfileView**: Displays and manages user profile information from SwiftData, allowing editing of personal details, dietary preferences, health goals, and app settings.
- **MapView**: Provides an interactive map interface for restaurant discovery, displaying location data from SwiftData's Restaurant models.
- **RecipeDetailView**: Presents comprehensive recipe information including ingredients, nutritional content, and cooking instructions. Offers save/remove functionality and original source linking.

#### Common UI Components
- **ContentLoadingView**: Provides standardized loading state presentation
- **ContentErrorView**: Standardizes error message display
- **RecipeCard**: Ensures consistent recipe presentation throughout the app
- **FilterSheet**: Offers standardized filtering interfaces for various content types

### Data Sources
- **Edamam Recipe API**: Comprehensive recipe database with nutritional information
- **MapKit Integration**: Location services for restaurant discovery
- **SwiftData**: Swift's persistence framework for saving user preferences and favorite recipes

## Getting Started

### Prerequisites
- iOS 17.0 or later
- Xcode 15.0 or later
- Apple Developer Account (for testing on physical devices)

### Installation
1. Clone the repository to your local machine
2. Open the project in Xcode
3. Set up your development team in the Signing & Capabilities tab
4. Build and run the application on your preferred simulator or device

## API Keys
The application uses the Edamam Recipe API for fetching recipe data. For security reasons, API keys are not included in the repository. Follow these steps to set up your own keys:

1. Register for API credentials at [Edamam Developer Portal](https://developer.edamam.com/)
2. Create a new file `Config.xconfig`
3. Copy the `Config.example.xcconfig` file to `Config.xcconfig`
4. Replace the placeholder values in `Config.xcconfig` with your actual API keys:

```
EDAMAM_APP_ID = your_app_id_here
EDAMAM_APP_KEY = your_app_key_here
```

> **Note**: Never commit your actual API keys to version control. The `Config.xcconfig` file is included in `.gitignore` to prevent accidental exposure of your credentials.

## Future Enhancements
- Meal scheduling with calendar integration
- Grocery list generation based on selected recipes
- Recipe sharing via social media
- Nutritional progress tracking
- Custom recipe creation and storage

## License
This project is intended for educational purposes. All rights reserved.

---

© 2025 Ayush Sachin Wattamwar, Hridaya Amol Dande 
