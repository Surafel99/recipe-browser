import 'dart:async';

import 'package:flutter/material.dart';

import '../models/meal.dart';
import '../services/api_exception.dart';
import '../services/meal_api_service.dart';
import 'meal_detail_screen.dart';

/// Category screen — lists all meals that belong to [category].
///
/// Bonus 3 (Pagination): Meals are displayed 10 at a time.
/// Scrolling to the bottom automatically loads the next page.
class CategoryScreen extends StatefulWidget {
  final String category;

  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  // ── Service ───────────────────────────────────────────────────────────────
  final MealApiService _service = MealApiService();

  // ── Full list & pagination state (Bonus 3) ────────────────────────────────
  static const int _pageSize = 10;

  List<Meal> _allMeals = [];      // full list from API (fetched once)
  List<Meal> _displayedMeals = []; // currently visible slice
  int _currentPage = 0;
  bool _hasMore = false;
  bool _isLoadingMore = false;

  // ── Initial load state ────────────────────────────────────────────────────
  bool _isLoading = true;
  Object? _error;

  // ── Scroll controller for infinite scroll ──────────────────────────────────
  final ScrollController _scrollController = ScrollController();

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMeals();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadMeals() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
        _allMeals = [];
        _displayedMeals = [];
        _currentPage = 0;
        _hasMore = false;
      });
    }

    try {
      final meals = await _service.fetchMealsByCategory(widget.category);
      if (mounted) {
        setState(() {
          _allMeals = meals;
          _isLoading = false;
        });
        _loadNextPage();
      }
    } on TimeoutException catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e; });
    } on FormatException catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e; });
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e; });
    }
  }

  // ── Pagination helpers (Bonus 3) ──────────────────────────────────────────

  void _loadNextPage() {
    final start = _currentPage * _pageSize;
    if (start >= _allMeals.length) {
      if (mounted) setState(() => _hasMore = false);
      return;
    }
    final end = (start + _pageSize).clamp(0, _allMeals.length);
    if (mounted) {
      setState(() {
        _displayedMeals.addAll(_allMeals.sublist(start, end));
        _currentPage++;
        _hasMore = end < _allMeals.length;
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_hasMore && !_isLoadingMore) {
        setState(() => _isLoadingMore = true);
        // Small delay so the loader is visible briefly
        Future.delayed(const Duration(milliseconds: 300), _loadNextPage);
      }
    }
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Loading state
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 72, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                _errorMessage(_error!),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadMeals,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // No data state
    if (_displayedMeals.isEmpty) {
      return const Center(child: Text('No meals found in this category.'));
    }

    // Data state — list with pagination footer
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      // +1 for the loader / "Load More" footer
      itemCount: _displayedMeals.length + (_hasMore || _isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Footer item
        if (index == _displayedMeals.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: _isLoadingMore
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _isLoadingMore = true);
                        Future.delayed(
                            const Duration(milliseconds: 200), _loadNextPage);
                      },
                      icon: const Icon(Icons.expand_more_rounded),
                      label: Text(
                        'Load More (${_allMeals.length - _displayedMeals.length} remaining)',
                      ),
                    ),
                  ),
          );
        }

        // Meal list tile
        final meal = _displayedMeals[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                meal.strMealThumb,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.restaurant_rounded, size: 40),
              ),
            ),
            title: Text(
              meal.strMeal,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Tap to view full recipe',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MealDetailScreen(mealId: meal.idMeal),
              ),
            ),
          ),
        );
      },
    );
  }
}
