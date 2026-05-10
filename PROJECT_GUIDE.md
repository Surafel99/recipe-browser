# 📘 Project Guide — Flutter Recipe Browser (Track C)

> This guide explains every file, how the bonus features work, and exactly how to verify each one is running correctly in your app.

---

## 1. Project File Map

```
flutter-recipe-browser/
├── README.md                          ← GitHub submission file
├── pubspec.yaml                       ← dependencies (http, url_launcher)
└── lib/
    ├── main.dart                      ← app start + green/yellow theme
    ├── models/
    │   ├── meal_category.dart         ← data class for one category
    │   └── meal.dart                  ← data class for one meal
    ├── services/
    │   ├── api_exception.dart         ← custom error class
    │   └── meal_api_service.dart      ← ALL network code + cache logic
    └── screens/
        ├── home_screen.dart           ← home page (grid + search)
        ├── category_screen.dart       ← meals list + pagination
        └── meal_detail_screen.dart    ← full recipe view
```

---

## 2. What Each File Does

### `main.dart`
- Starts the app with `runApp()`
- Sets the **green (`#2E7D32`) and yellow (`#F9A825`) Material 3 theme**
- Points to `HomeScreen` as the first page

### `lib/models/meal_category.dart`
- Stores: `idCategory`, `strCategory`, `strCategoryThumb`, `strCategoryDescription`
- `fromJson()` — converts raw API JSON → Dart object
- `toJson()` — converts object → Map (required by assignment)
- `copyWith()` — creates modified copy (required by assignment)
- All fields are `final` (immutable)

### `lib/models/meal.dart`
- Stores: `idMeal`, `strMeal`, `strMealThumb`, `strCategory`, `strArea`, `strInstructions`, `strYoutube`, `ingredients`
- The 20 `strIngredientN` / `strMeasureN` fields from the API are automatically combined into a clean `List<String> ingredients`
- Same `fromJson`, `toJson`, `copyWith` pattern

### `lib/services/api_exception.dart`
- A custom exception class with `statusCode` and `message`
- Thrown by `_checkResponse()` whenever the server returns anything other than HTTP 200

### `lib/services/meal_api_service.dart`
- **The only file that imports `package:http/http.dart`**
- Contains all 4 API methods: `fetchCategories()`, `fetchMealsByCategory()`, `fetchMealById()`, `searchMeals()`
- **Bonus 2 cache is here** — see Section 4 below
- Timeout: 30 seconds on every request
- `_checkResponse()` throws `ApiException` for non-200 responses

### `lib/screens/home_screen.dart`
- Shows all categories in a **4-column green/yellow grid**
- **Bonus 1 debounce search** is here — see Section 3
- **Bonus 2 cache badge** — shows ⚡ Cached in the header
- Pull-to-refresh supported

### `lib/screens/category_screen.dart`
- Shows meals for a selected category (e.g. Beef, Chicken)
- **Bonus 3 pagination** — loads 10 at a time — see Section 5
- Handles all error states + Retry button

### `lib/screens/meal_detail_screen.dart`
- Shows full recipe: image, area chip, numbered ingredients, step-by-step instructions
- Red YouTube button opens the video in external browser via `url_launcher`
- Handles all error states + Retry button

---

## 3. Bonus 1 — Search Debouncing ✅

### Where the code is
**File:** `lib/screens/home_screen.dart`

```dart
Timer? _debounce;

void _onSearchChanged(String query) {
  if (_debounce?.isActive ?? false) _debounce!.cancel();  // cancel old timer

  if (query.trim().isEmpty) { /* clear search */ return; }

  setState(() => _isDebouncing = true); // show spinner in search bar

  _debounce = Timer(const Duration(milliseconds: 400), () {
    // This only runs 400ms AFTER the user stops typing
    setState(() {
      _isSearching = true;
      _isDebouncing = false;
      _searchFuture = _service.searchMeals(query.trim());
    });
  });
}
```

### How to verify it is working
1. Open the app and tap the search bar
2. Type quickly: `C`, `h`, `i`, `c`, `k`, `e`, `n`
3. **Watch the search icon** — it turns into a small spinning circle while you type
4. **Stop typing** — after exactly 400ms, the spinner disappears and results appear
5. The API was called only **once** (for "Chicken"), not 7 times (once per letter)
6. To confirm: open Flutter DevTools → Network tab — you will see only 1 HTTP request per search, not one per keystroke

---

## 4. Bonus 2 — Local Cache with TTL ✅

### Where the code is
**File:** `lib/services/meal_api_service.dart`

```dart
// These 3 fields store the cache
static const Duration _cacheTtl = Duration(minutes: 5);
List<MealCategory>? _cachedCategories;   // the stored data
DateTime? _cacheTimestamp;               // when it was stored

// This getter checks if cache is still fresh
bool get isCacheValid =>
    _cachedCategories != null &&
    _cacheTimestamp != null &&
    DateTime.now().difference(_cacheTimestamp!) < _cacheTtl;

Future<List<MealCategory>> fetchCategories() async {
  if (isCacheValid) return _cachedCategories!;  // ← serve from cache instantly

  // ... fetch from network ...

  _cachedCategories = result;          // ← save to cache
  _cacheTimestamp = DateTime.now();    // ← record when we saved it
  return result;
}
```

**File:** `lib/screens/home_screen.dart`

```dart
void _loadCategories() {
  final cacheHit = _service.isCacheValid; // check BEFORE fetching
  setState(() {
    _fromCache = cacheHit;               // remember if it came from cache
    _categoriesFuture = _service.fetchCategories();
  });
}
```

The **⚡ Cached** golden badge in the header is shown when `_fromCache == true`.

### How to verify it is working

**Step-by-step test:**

1. **First launch** — open the app. Categories load with a spinner. **No badge** appears. This is a live network fetch.

2. **Navigate away** — tap any category (e.g. Beef) to go to the next screen.

3. **Press back** — return to the home screen.

4. **⚡ Cached badge appears** in the top-right of the green header. The categories load instantly with **no spinner** — data came from memory cache.

5. **Wait 5 minutes** — after the TTL expires, press the refresh (pull down) or hot-reload. The badge **disappears** and a spinner shows briefly — a fresh network call was made.

> 💡 **Quick test tip:** To see the badge immediately without navigating away, open the app, let it load, then press the Flutter hot-reload button (r in terminal). The `_loadCategories()` method will be called again, `isCacheValid` will be `true`, and the badge appears.

---

## 5. Bonus 3 — Pagination ✅

### Where the code is
**File:** `lib/screens/category_screen.dart`

```dart
static const int _pageSize = 10;
List<Meal> _allMeals = [];       // full list from API (fetched once)
List<Meal> _displayedMeals = []; // the visible slice shown on screen
int _currentPage = 0;
bool _hasMore = false;

void _loadNextPage() {
  final start = _currentPage * _pageSize;    // e.g. page 0 → start=0
  final end = (start + _pageSize)            // e.g. end=10
      .clamp(0, _allMeals.length);
  setState(() {
    _displayedMeals.addAll(_allMeals.sublist(start, end)); // add 10 more
    _currentPage++;
    _hasMore = end < _allMeals.length;       // any more left?
  });
}
```

### How to verify it is working
1. Tap any large category like **Chicken** or **Beef**
2. The list shows exactly **10 meals**
3. At the bottom you see a button: **"Load More (N remaining)"**
4. Tap it — 10 more meals appear
5. If you scroll slowly to the bottom, the next page also **loads automatically**
6. When all meals are shown, the Load More button disappears

---

## 6. How All 5 Error Types Are Handled

| Error | How to trigger it | Message you see |
|-------|-------------------|-----------------|
| **No internet** | Turn on Airplane Mode, open the app | "No internet connection. Please check your network." |
| **Timeout** | Very slow connection or server down | "Request timed out. Please try again." |
| **Non-200 HTTP** | Server sends 404/500 (automatic) | "Server error 404: Server returned status 404." |
| **Format error** | Malformed JSON from server (automatic) | "Unexpected data format received." |
| **Generic** | Any other unexpected error | "An unexpected error occurred: …" |

Every error screen has a **Retry** button that re-fetches the data.

**To test the error screen during your screen recording:**
1. Let the app fully load categories
2. Turn on **Airplane Mode**
3. Tap any category — wait — the error screen appears with the wifi icon and Retry button
4. Turn Airplane Mode **off**
5. Tap **Retry** — data loads successfully

---

## 7. Git Commit Strategy (get your 5+ commits)

```bash
git init
git add pubspec.yaml lib/main.dart
git commit -m "chore: initial project setup with dependencies and theme"

git add lib/services/api_exception.dart
git commit -m "feat: add custom ApiException class"

git add lib/models/
git commit -m "feat: add MealCategory and Meal model classes with fromJson/toJson/copyWith"

git add lib/services/meal_api_service.dart
git commit -m "feat: implement MealApiService with all endpoints and 5-min cache (Bonus 2)"

git add lib/screens/home_screen.dart
git commit -m "feat: home screen with 4-column grid, search debounce (Bonus 1) and cache badge"

git add lib/screens/category_screen.dart
git commit -m "feat: category screen with meal list and infinite scroll pagination (Bonus 3)"

git add lib/screens/meal_detail_screen.dart
git commit -m "feat: meal detail screen with ingredients, instructions and YouTube button"

git add README.md
git commit -m "docs: add final README with setup instructions and bonus documentation"
```

---

## 8. Screen Recording Checklist

Your recording must show all of these:

- [ ] App opens → spinner → categories load in green/yellow 4-column grid
- [ ] Tap a category → meals list loads (10 at a time)
- [ ] Scroll to bottom → Load More button appears → tap it → more meals load
- [ ] Tap a meal → full recipe loads (ingredients + instructions + YouTube button)
- [ ] Go back to home → **⚡ Cached badge** appears (cache working)
- [ ] Tap the search bar → type "Chicken" → results appear after 400ms (debounce working)
- [ ] Turn on Airplane Mode → tap a category → error screen with Retry button appears
- [ ] Turn off Airplane Mode → tap Retry → data loads successfully

---

*Surafel — Software Engineering 4th Year · Addis Ababa Institute of Technology (AAiT)*
