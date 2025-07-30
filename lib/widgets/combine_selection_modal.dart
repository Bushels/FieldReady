/**
 * Full-screen combine selection modal for FieldReady
 * Features command-palette search, responsive grid, and smooth animations
 */

import 'package:field_ready/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/combine_data.dart';
import '../utils/fuzzy_search.dart';
import '../widgets/combine_card.dart';
import '../widgets/command_search_bar.dart';

class CombineSelectionModal extends StatefulWidget {
  final Function(CombineData) onCombineSelected;
  final CombineData? selectedCombine;

  const CombineSelectionModal({
    super.key,
    required this.onCombineSelected,
    this.selectedCombine,
  });

  @override
  State<CombineSelectionModal> createState() => _CombineSelectionModalState();
}

class _CombineSelectionModalState extends State<CombineSelectionModal>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _gridController;
  
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _gridAnimation;

  final FirestoreService _firestoreService = FirestoreService();
  late Future<List<CombineData>> _combinesFuture;
  List<CombineData> _allCombines = [];
  List<CombineData> _filteredCombines = [];
  String _currentQuery = '';
  String _selectedFilter = 'All';
  CombineData? _selectedCombine;

  final List<String> _filterOptions = [
    'All',
    'Popular',
    'Top Rated',
    'John Deere',
    'Case IH',
    'New Holland',
    'Claas',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCombine = widget.selectedCombine;
    _combinesFuture = _firestoreService.getCombines();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _gridController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _gridAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _gridController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward().then((_) {
      _gridController.forward();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _gridController.dispose();
    super.dispose();
  }

  void _handleSearchChanged(String query) {
    setState(() {
      _currentQuery = query;
      _updateFilteredCombines();
    });
  }

  void _handleFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
      _updateFilteredCombines();
    });
  }

  void _updateFilteredCombines() {
    List<CombineData> results = _allCombines;

    // Apply filter first
    switch (_selectedFilter) {
      case 'Popular':
        results.sort((a, b) => b.popularityScore.compareTo(a.popularityScore));
        break;
      case 'Top Rated':
        results.sort((a, b) => b.avgRating.compareTo(a.avgRating));
        break;
      case 'John Deere':
      case 'Case IH':
      case 'New Holland':
      case 'Claas':
        results = _allCombines.where((c) => c.brand == _selectedFilter).toList();
        break;
    }

    // Apply search query
    if (_currentQuery.isNotEmpty) {
      final searchResults = FuzzySearch.searchCombines(_currentQuery, _allCombines);
      final searchedCombines = searchResults.map((r) => r.item).toSet();
      results = results.where((c) => searchedCombines.contains(c)).toList();
    }

    setState(() {
      _filteredCombines = results;
    });
  }

  void _handleCombineSelected(CombineData combine) {
    setState(() {
      _selectedCombine = combine;
    });
    
    // Haptic feedback
    HapticFeedback.selectionClick();
    
    // Animate selection and close modal
    Future.delayed(const Duration(milliseconds: 200), () {
      _closeModal();
      widget.onCombineSelected(combine);
    });
  }

  void _closeModal() {
    _gridController.reverse();
    _slideController.reverse().then((_) {
      _fadeController.reverse().then((_) {
        Navigator.of(context).pop();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _closeModal();
        }
      },
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, _) {
          return Container(
            color: Colors.black.withOpacity(_fadeAnimation.value * 0.5),
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildSearchSection(),
                    _buildFilterSection(),
                    Expanded(
                      child: FutureBuilder<List<CombineData>>(
                        future: _combinesFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return const Center(child: Text('Error loading combines'));
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(child: Text('No combines found'));
                          }

                          _allCombines = snapshot.data!;
                          _updateFilteredCombines();

                          return _buildCombineGrid();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Select Your Combine',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose the combine that matches your operation',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _closeModal,
                icon: Icon(
                  Icons.close,
                  color: Colors.grey[600],
                ),
                tooltip: 'Close',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      color: Colors.white,
      child: CommandSearchBar(
        onSearchChanged: _handleSearchChanged,
        hintText: 'Search by brand, model, or capability...',
        autofocus: false,
        combines: _allCombines,
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final filter = _filterOptions[index];
          final isSelected = filter == _selectedFilter;
          
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (_) => _handleFilterChanged(filter),
              backgroundColor: Colors.grey[100],
              selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              side: BorderSide(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCombineGrid() {
    if (_filteredCombines.isEmpty) {
      return _buildEmptyState();
    }

    return AnimatedBuilder(
      animation: _gridAnimation,
      builder: (context, _) {
        return Opacity(
          opacity: _gridAnimation.value,
          child: Transform.translate(
            offset: Offset(0, (1 - _gridAnimation.value) * 50),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = _calculateCrossAxisCount(constraints.maxWidth);
                  
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _filteredCombines.length,
                    itemBuilder: (context, index) {
                      final combine = _filteredCombines[index];
                      
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 200 + (index * 50)),
                        curve: Curves.easeOutCubic,
                        child: CombineCard(
                          combine: combine,
                          isSelected: _selectedCombine?.id == combine.id,
                          onTap: () => _handleCombineSelected(combine),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No combines found',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _currentQuery = '';
                _selectedFilter = 'All';
                _updateFilteredCombines();
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  int _calculateCrossAxisCount(double width) {
    if (width < 600) {
      return 1; // Mobile: 1 column
    } else if (width < 900) {
      return 2; // Tablet: 2 columns
    } else if (width < 1200) {
      return 3; // Small desktop: 3 columns
    } else {
      return 4; // Large desktop: 4 columns
    }
  }
}

/// Helper function to show the combine selection modal
Future<CombineData?> showCombineSelectionModal({
  required BuildContext context,
  required Function(CombineData) onCombineSelected,
  CombineData? selectedCombine,
}) {
  return showModalBottomSheet<CombineData>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.transparent,
    builder: (context) => CombineSelectionModal(
      onCombineSelected: onCombineSelected,
      selectedCombine: selectedCombine,
    ),
  );
}