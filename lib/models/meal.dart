/// Model class for a Meal returned by TheMealDB.
/// Used for both the brief list view (from /filter.php) and the full detail
/// view (from /lookup.php). All fields are final. Provides fromJson, toJson,
/// and copyWith.
class Meal {
  final String idMeal;
  final String strMeal;
  final String strMealThumb;
  final String? strCategory;
  final String? strArea;
  final String? strInstructions;
  final String? strYoutube;

  /// Combined list of "measure ingredient" strings, e.g. "2 cups Flour".
  /// Built by [fromJson] from the 20 strIngredientN / strMeasureN fields.
  final List<String> ingredients;

  const Meal({
    required this.idMeal,
    required this.strMeal,
    required this.strMealThumb,
    this.strCategory,
    this.strArea,
    this.strInstructions,
    this.strYoutube,
    this.ingredients = const [],
  });

  /// Parses a JSON map (either from /filter.php or /lookup.php) into a [Meal].
  /// The 20 ingredient/measure pairs are collapsed into [ingredients].
  factory Meal.fromJson(Map<String, dynamic> json) {
    final List<String> ingredientList = [];
    for (int i = 1; i <= 20; i++) {
      final ingredient =
          (json['strIngredient$i'] as String? ?? '').trim();
      final measure = (json['strMeasure$i'] as String? ?? '').trim();
      if (ingredient.isNotEmpty) {
        final entry =
            measure.isNotEmpty ? '$measure $ingredient' : ingredient;
        ingredientList.add(entry);
      }
    }

    return Meal(
      idMeal: json['idMeal'] as String,
      strMeal: json['strMeal'] as String,
      strMealThumb: json['strMealThumb'] as String? ?? '',
      strCategory: json['strCategory'] as String?,
      strArea: json['strArea'] as String?,
      strInstructions: json['strInstructions'] as String?,
      strYoutube: json['strYoutube'] as String?,
      ingredients: ingredientList,
    );
  }

  /// Converts this model to a JSON map (ingredients list is not serialised
  /// since the API stores them as numbered fields).
  Map<String, dynamic> toJson() => {
        'idMeal': idMeal,
        'strMeal': strMeal,
        'strMealThumb': strMealThumb,
        'strCategory': strCategory,
        'strArea': strArea,
        'strInstructions': strInstructions,
        'strYoutube': strYoutube,
      };

  /// Returns a copy of this model with the given fields replaced.
  Meal copyWith({
    String? idMeal,
    String? strMeal,
    String? strMealThumb,
    String? strCategory,
    String? strArea,
    String? strInstructions,
    String? strYoutube,
    List<String>? ingredients,
  }) {
    return Meal(
      idMeal: idMeal ?? this.idMeal,
      strMeal: strMeal ?? this.strMeal,
      strMealThumb: strMealThumb ?? this.strMealThumb,
      strCategory: strCategory ?? this.strCategory,
      strArea: strArea ?? this.strArea,
      strInstructions: strInstructions ?? this.strInstructions,
      strYoutube: strYoutube ?? this.strYoutube,
      ingredients: ingredients ?? this.ingredients,
    );
  }
}
