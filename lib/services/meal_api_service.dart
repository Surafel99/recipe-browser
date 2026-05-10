import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/meal.dart';
import '../models/meal_category.dart';
import 'api_exception.dart';

/// Service class that handles ALL HTTP communication with TheMealDB API.
/// No screen or widget should import 'package:http/http.dart' directly.
///
/// NOTE: dart:io is intentionally NOT imported here because it does not
/// exist on Flutter Web. Network errors are caught generically in screens.
///
/// Bonus features built in:
///   • In-memory cache with a 5-minute TTL for [fetchCategories].
///   • [isCacheValid] getter so the UI can show a "Cached" badge.
class MealApiService {
  // ── Configuration ────────────────────────────────────────────────────────

  static const String _baseUrl = 'www.themealdb.com';
  static const String _basePath = '/api/json/v1/1';
  static const Duration _timeout = Duration(seconds: 30);

  /// Only Accept header — sending Content-Type on GET triggers a CORS
  /// preflight that TheMealDB does not support on Flutter Web.
  final Map<String, String> _headers = const {
    'Accept': 'application/json',
  };

  // ── Cache (Bonus 2) ──────────────────────────────────────────────────────

  static const Duration _cacheTtl = Duration(minutes: 5);
  List<MealCategory>? _cachedCategories;
  DateTime? _cacheTimestamp;

  /// Returns true when a valid (non-expired) category cache exists.
  bool get isCacheValid =>
      _cachedCategories != null &&
      _cacheTimestamp != null &&
      DateTime.now().difference(_cacheTimestamp!) < _cacheTtl;

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Throws [ApiException] if [response] has a non-200 status code.
  void _checkResponse(http.Response response) {
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Server returned status ${response.statusCode}.',
      );
    }
  }

  // ── Public API methods ────────────────────────────────────────────────────

  /// GET /categories.php — fetch all meal categories.
  ///
  /// Results are cached in memory for [_cacheTtl]. Subsequent calls within
  /// the TTL return the cached list instantly (Bonus 2).
  Future<List<MealCategory>> fetchCategories() async {
    // Return cache if still valid
    if (isCacheValid) return _cachedCategories!;

    final uri = Uri.https(_baseUrl, '$_basePath/categories.php');
    final response =
        await http.get(uri, headers: _headers).timeout(_timeout);
    _checkResponse(response);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['categories'] as List<dynamic>;
    final result = data
        .map((e) => MealCategory.fromJson(e as Map<String, dynamic>))
        .toList();

    // Store in cache
    _cachedCategories = result;
    _cacheTimestamp = DateTime.now();

    return result;
  }

  /// GET /filter.php?c={category} — fetch all meals for a given category name.
  Future<List<Meal>> fetchMealsByCategory(String category) async {
    final uri = Uri.https(
      _baseUrl,
      '$_basePath/filter.php',
      {'c': category},
    );
    final response =
        await http.get(uri, headers: _headers).timeout(_timeout);
    _checkResponse(response);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['meals'] as List<dynamic>;
    return data
        .map((e) => Meal.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /lookup.php?i={mealId} — fetch full recipe details for a single meal.
  Future<Meal> fetchMealById(String mealId) async {
    final uri = Uri.https(
      _baseUrl,
      '$_basePath/lookup.php',
      {'i': mealId},
    );
    final response =
        await http.get(uri, headers: _headers).timeout(_timeout);
    _checkResponse(response);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final meals = body['meals'] as List<dynamic>;
    return Meal.fromJson(meals.first as Map<String, dynamic>);
  }

  /// GET /search.php?s={query} — search meals by name (used in Bonus 1 debounce).
  Future<List<Meal>> searchMeals(String query) async {
    final uri = Uri.https(
      _baseUrl,
      '$_basePath/search.php',
      {'s': query},
    );
    final response =
        await http.get(uri, headers: _headers).timeout(_timeout);
    _checkResponse(response);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final meals = body['meals'] as List<dynamic>? ?? [];
    return meals
        .map((e) => Meal.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
