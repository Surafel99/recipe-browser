import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/meal.dart';
import '../services/api_exception.dart';
import '../services/meal_api_service.dart';

/// Meal detail screen — shows the full recipe for a single meal.
///
/// Displays: hero image, area/category chips, ingredients list,
/// step-by-step instructions, and a YouTube button (url_launcher).
///
/// Uses FutureBuilder with all 4 states handled:
///   1. ConnectionState.waiting → CircularProgressIndicator
///   2. hasError              → error message + Retry button
///   3. !hasData              → "Meal not found"
///   4. hasData               → full recipe UI
class MealDetailScreen extends StatefulWidget {
  final String mealId;

  const MealDetailScreen({super.key, required this.mealId});

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  final MealApiService _service = MealApiService();
  late Future<Meal> _mealFuture;

  @override
  void initState() {
    super.initState();
    _loadMeal();
  }

  void _loadMeal() {
    setState(() {
      _mealFuture = _service.fetchMealById(widget.mealId);
    });
  }

  // ── Error message helper ───────────────────────────────────────────────────

  String _errorMessage(Object error) {
    if (error is TimeoutException) return 'Request timed out. Please try again.';
    if (error is ApiException) {
      return 'Server error ${error.statusCode}: ${error.message}';
    }
    if (error is FormatException) return 'Unexpected data format received.';
    final msg = error.toString().toLowerCase();
    if (msg.contains('socket') || msg.contains('network') || msg.contains('connection')) {
      return 'No internet connection. Please check your network.';
    }
    return 'An unexpected error occurred: $error';
  }

  // ── YouTube launcher ───────────────────────────────────────────────────────

  Future<void> _openYoutube(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open YouTube link.')),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Meal>(
        future: _mealFuture,
        builder: (context, snapshot) {
          // State 1: Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // State 2: Error
          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          size: 72, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage(snapshot.error!),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _loadMeal,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // State 3: No data
          if (!snapshot.hasData) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('Meal not found.')),
            );
          }

          // State 4: Data
          final meal = snapshot.data!;
          return _buildRecipeView(meal);
        },
      ),
    );
  }

  // ── Recipe detail UI ──────────────────────────────────────────────────────

  Widget _buildRecipeView(Meal meal) {
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        // ── Hero image + title ────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              meal.strMeal,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                fontSize: 16,
              ),
            ),
            background: meal.strMealThumb.isNotEmpty
                ? Image.network(
                    meal.strMealThumb,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: colorScheme.surfaceContainerHighest,
                      child:
                          const Icon(Icons.restaurant_rounded, size: 80),
                    ),
                  )
                : Container(color: colorScheme.surfaceContainerHighest),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Meta chips ──────────────────────────────────────────
                Wrap(
                  spacing: 8,
                  children: [
                    if (meal.strCategory != null)
                      Chip(
                        avatar: const Icon(Icons.category_rounded, size: 16),
                        label: Text(meal.strCategory!),
                        visualDensity: VisualDensity.compact,
                      ),
                    if (meal.strArea != null)
                      Chip(
                        avatar: const Icon(Icons.place_rounded, size: 16),
                        label: Text(meal.strArea!),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Ingredients ─────────────────────────────────────────
                _SectionTitle(title: 'Ingredients', icon: Icons.shopping_basket_rounded),
                const SizedBox(height: 12),
                if (meal.ingredients.isEmpty)
                  const Text('No ingredients listed.')
                else
                  ...meal.ingredients.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${entry.key + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(fontSize: 14, height: 1.6),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                const SizedBox(height: 28),

                // ── Instructions ─────────────────────────────────────────
                if (meal.strInstructions != null &&
                    meal.strInstructions!.isNotEmpty) ...[
                  _SectionTitle(
                      title: 'Instructions', icon: Icons.menu_book_rounded),
                  const SizedBox(height: 12),
                  // Split instructions into numbered steps on line breaks
                  ..._parseInstructions(meal.strInstructions!).asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${entry.key + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                  fontSize: 14, height: 1.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // ── YouTube button ────────────────────────────────────────
                if (meal.strYoutube != null && meal.strYoutube!.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF0000),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _openYoutube(meal.strYoutube!),
                      icon: const Icon(Icons.play_circle_fill_rounded, size: 24),
                      label: const Text(
                        'Watch on YouTube',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Splits the raw instructions string into clean, non-empty paragraphs.
  List<String> _parseInstructions(String raw) {
    return raw
        .split(RegExp(r'\r?\n'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
}

// ── Reusable section title widget ─────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
