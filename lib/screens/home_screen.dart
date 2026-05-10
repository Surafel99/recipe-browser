import 'dart:async';

import 'package:flutter/material.dart';

import '../models/meal.dart';
import '../models/meal_category.dart';
import '../services/api_exception.dart';
import '../services/meal_api_service.dart';
import 'category_screen.dart';
import 'meal_detail_screen.dart';

/// Home screen — shows all meal categories in a beautiful green/yellow grid.
///
/// Bonus 1 (Search Debounce): Search bar with 400ms debounce.
/// Bonus 2 (Cache): In-memory cache with "Cached" badge in AppBar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MealApiService _service = MealApiService();

  late Future<List<MealCategory>> _categoriesFuture;
  bool _fromCache = false;

  // Search / debounce (Bonus 1)
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isSearching = false;
  bool _isDebouncing = false;
  Future<List<Meal>>? _searchFuture;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _loadCategories() {
    final cacheHit = _service.isCacheValid;
    if (mounted) {
      setState(() {
        _fromCache = cacheHit;
        _categoriesFuture = _service.fetchCategories();
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (query.trim().isEmpty) {
      if (mounted) setState(() { _isSearching = false; _isDebouncing = false; _searchFuture = null; });
      return;
    }
    if (mounted) setState(() => _isDebouncing = true);
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() { _isSearching = true; _isDebouncing = false; _searchFuture = _service.searchMeals(query.trim()); });
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  String _errorMessage(Object error) {
    if (error is TimeoutException) return 'Request timed out. Please try again.';
    if (error is ApiException) return 'Server error ${error.statusCode}: ${error.message}';
    if (error is FormatException) return 'Unexpected data format received.';
    final msg = error.toString().toLowerCase();
    if (msg.contains('socket') || msg.contains('network') || msg.contains('connection')) {
      return 'No internet connection. Please check your network.';
    }
    return 'An unexpected error occurred: $error';
  }

  Widget _buildError(Object error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded, size: 48, color: Colors.red.shade400),
            ),
            const SizedBox(height: 20),
            Text(
              _errorMessage(error),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF444444)),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      body: CustomScrollView(
        slivers: [
          // ── Big green header ────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: const Color(0xFF2E7D32),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      bottom: -40,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9A825).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Title content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9A825),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text('🍽️', style: TextStyle(fontSize: 22)),
                              ),
                              const SizedBox(width: 12),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Recipe Browser',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    'Discover meals from around the world',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Cached badge
                    if (_fromCache)
                      Positioned(
                        top: 50,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9A825),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.offline_bolt_rounded, size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text('Cached', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Search bar ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search recipes…',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: _isDebouncing
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : const Icon(Icons.search_rounded, color: Color(0xFF2E7D32)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                            onPressed: _clearSearch,
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ),

          // ── Section label ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9A825),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isSearching ? 'Search Results' : 'All Categories',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────
          if (_isSearching)
            _buildSearchResultsSliver()
          else
            _buildCategoryGridSliver(),
        ],
      ),
    );
  }

  // ── Category grid ─────────────────────────────────────────────────────────

  Widget _buildCategoryGridSliver() {
    return SliverFillRemaining(
      child: FutureBuilder<List<MealCategory>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF2E7D32)),
                  SizedBox(height: 16),
                  Text('Loading recipes…', style: TextStyle(color: Color(0xFF2E7D32))),
                ],
              ),
            );
          }
          if (snapshot.hasError) return _buildError(snapshot.error!, _loadCategories);
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No categories found.'));
          }
          final categories = snapshot.data!;
          return RefreshIndicator(
            color: const Color(0xFF2E7D32),
            onRefresh: () async => _loadCategories(),
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.72,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                // Alternate card accent: green or yellow
                final isYellow = index % 3 == 1;
                return _CategoryCard(
                  category: cat,
                  accentColor: isYellow ? const Color(0xFFF9A825) : const Color(0xFF2E7D32),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CategoryScreen(category: cat.strCategory)),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ── Search results ────────────────────────────────────────────────────────

  Widget _buildSearchResultsSliver() {
    return SliverFillRemaining(
      child: FutureBuilder<List<Meal>>(
        future: _searchFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
          }
          if (snapshot.hasError) {
            return _buildError(snapshot.error!, () => _onSearchChanged(_searchController.text));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('No meals found', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                ],
              ),
            );
          }
          final meals = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: meals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final meal = meals[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(meal.strMealThumb, width: 60, height: 60, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.restaurant_rounded, size: 40)),
                  ),
                  title: Text(meal.strMeal, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(meal.strCategory ?? '', style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 12)),
                  trailing: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: const Color(0xFFF1F8E9), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.chevron_right_rounded, color: Color(0xFF2E7D32), size: 20),
                  ),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MealDetailScreen(mealId: meal.idMeal))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Category card ─────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.onTap,
    required this.accentColor,
  });

  final MealCategory category;
  final VoidCallback onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image with rounded top corners
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      category.strCategoryThumb,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : Container(
                              color: const Color(0xFFF1F8E9),
                              child: Center(child: CircularProgressIndicator(color: accentColor, strokeWidth: 2)),
                            ),
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFF1F8E9),
                        child: const Center(child: Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey)),
                      ),
                    ),
                    // Gradient overlay at bottom of image
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black.withOpacity(0.3), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom info area
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                border: Border(top: BorderSide(color: accentColor.withOpacity(0.2), width: 1)),
              ),
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          category.strCategory,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: Color(0xFF1B5E20),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (category.strCategoryDescription.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      category.strCategoryDescription,
                      style: TextStyle(fontSize: 9, color: Colors.grey.shade500, height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
