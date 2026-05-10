# Flutter Recipe Browser



Name Surafel Alebachew 
Student ID ATE/3176/15
Track C — Recipe Browser App 
API [TheMealDB](https://www.themealdb.com/api/json/v1/1) — Free, no API key needed 
Instructor |Abel Tadesse 



##  App Description

A Flutter recipe browser that lets users explore meal categories, browse meals within a category, and view full recipes — including numbered ingredients, step-by-step instructions, and a YouTube video link. All data is fetched live from the free TheMealDB public REST API. No API key is required.

---

##  Running the App Locally

### Prerequisites
- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`
- Android Studio or VS Code with Flutter extension
- Android emulator, iOS simulator, or a physical device

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/<surafel99>/flutter-recipe-browser.git
cd flutter-recipe-browser

# 2. Install dependencies
flutter pub get

# 3. Run the app
flutter run
```

> ✅ No `.env` file needed — TheMealDB is completely free and requires no API key.

---

##  API Endpoints Used

| Endpoint | Screen | Purpose |
|----------|--------|---------|
| `GET /categories.php` | Home | Fetch all meal categories |
| `GET /filter.php?c={category}` | Category | All meals in a selected category |
| `GET /lookup.php?i={mealId}` | Detail | Full recipe for one meal |
| `GET /search.php?s={query}` | Home (search) | Search meals by name |

**Base URL:** `https://www.themealdb.com/api/json/v1/1`

---

##  Project Structure

```
lib/
├── main.dart                          # App entry, MaterialApp, green/yellow theme
├── models/
│   ├── meal_category.dart             # MealCategory model (fromJson/toJson/copyWith)
│   └── meal.dart                      # Meal model (fromJson/toJson/copyWith)
├── services/
│   ├── meal_api_service.dart          # ALL HTTP logic + in-memory cache
│   └── api_exception.dart             # Custom ApiException class
└── screens/
    ├── home_screen.dart               # Category grid + debounced search + cache badge
    ├── category_screen.dart           # Meals list with infinite scroll pagination
    └── meal_detail_screen.dart        # Full recipe: ingredients, instructions, YouTube
```

---

##  Bonus Tasks Implemented

### Bonus 1 — Search Debouncing (+5 marks) 
A search bar on the Home screen calls the API **400 ms after the user stops typing** — never on every keystroke. A `CircularProgressIndicator` replaces the search icon while the debounce timer is active. Implemented with `dart:async Timer` in `home_screen.dart`.

### Bonus 2 — Local Caching with TTL (+5 marks) 
The category list is cached in memory with a **5-minute TTL**. On re-visit within 5 minutes the list loads instantly from cache. A golden **⚡ Cached** badge appears in the top-right of the header when data is served from cache. Implemented entirely in `meal_api_service.dart`.

**How to verify it is working:**
1. Open the app — categories load from the network (no badge).
2. Navigate away (go into a category, come back, or hot-reload).
3. The **⚡ Cached** badge appears in the green header — data was served instantly from memory.
4. Wait 5 minutes and refresh — the badge disappears and a fresh network call is made.

### Bonus 3 — Pagination (+5 marks) 
The category meals screen (e.g. Beef, Chicken) loads **10 meals at a time**. Scrolling near the bottom triggers the next page automatically. A **"Load More (N remaining)"** button also appears for manual control. Implemented with `ScrollController` in `category_screen.dart`.

---

## 🛡️ Error Handling

| Error | Message shown |
|-------|--------------|
| No internet | "No internet connection. Please check your network." |
| Timeout (>30 s) | "Request timed out. Please try again." |
| Non-200 HTTP | "Server error {code}: {message}" |
| Malformed JSON | "Unexpected data format received." |
| Any other | "An unexpected error occurred: {detail}" |

All error screens show a **Retry** button. Pull-to-refresh is available on the home screen.

---



## Dependencies

```yaml
http: ^1.2.1          # All HTTP requests (required by assignment)
url_launcher: ^6.3.0  # Open YouTube links in external browser
```

---



*Submitted by Surafel Alebachew Asefa — Software Engineering, 4th Year · Addis Ababa Institute of Technology (AAiT)*
