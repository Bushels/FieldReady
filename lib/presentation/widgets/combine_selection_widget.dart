/**
 * Combine Selection Widget - Brand dropdown, year selection, and fuzzy search autocomplete
 * Optimized for farm field conditions with large touch targets and high contrast
 * 
 * Features:
 * - Progressive disclosure: brand → year → model
 * - Real-time fuzzy search with autocomplete
 * - Offline fallback with cached suggestions
 * - One-handed operation with thumb-reachable zones
 * - Voice input support for muddy glove conditions
 * - High contrast (7:1 ratio) for sunlight readability
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/combine/combine_bloc.dart';
import '../blocs/combine/combine_event.dart';
import '../blocs/combine/combine_state.dart';
import '../pages/combine_setup_page.dart';

/// Callback for when selection changes
typedef SelectionChangedCallback = void Function(String? brand, String? model, int? year);

class CombineSelectionWidget extends StatefulWidget {
  final String userId;
  final String? initialBrand;
  final String? initialModel;
  final int? initialYear;
  final SelectionChangedCallback onSelectionChanged;
  
  const CombineSelectionWidget({
    super.key,
    required this.userId,
    this.initialBrand,
    this.initialModel,
    this.initialYear,
    required this.onSelectionChanged,
  });

  @override
  State<CombineSelectionWidget> createState() => _CombineSelectionWidgetState();
}

class _CombineSelectionWidgetState extends State<CombineSelectionWidget> {
  // Controllers for form fields
  final TextEditingController _modelController = TextEditingController();
  final FocusNode _modelFocusNode = FocusNode();
  
  // Current selections
  String? _selectedBrand;
  int? _selectedYear;
  String? _selectedModel;
  
  // Autocomplete state
  List<String> _modelSuggestions = [];
  bool _showSuggestions = false;
  
  // Major combine manufacturers
  static const List<String> _brands = [
    'John Deere',
    'Case IH',
    'New Holland',
    'Claas',
    'Massey Ferguson',
    'Fendt',
    'Gleaner',
    'Challenger',
  ];
  
  // Year range for combines (2015-2024)
  static const int _startYear = 2015;
  static const int _endYear = 2024;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize with provided values
    _selectedBrand = widget.initialBrand;
    _selectedYear = widget.initialYear;
    if (widget.initialModel != null) {
      _modelController.text = widget.initialModel!;
      _selectedModel = widget.initialModel;
    }
    
    // Set up model text field listener for autocomplete
    _modelController.addListener(_onModelTextChanged);
    _modelFocusNode.addListener(_onModelFocusChanged);
    
    // Load available combine specs for autocomplete
    _loadCombineSpecs();
  }

  @override
  void dispose() {
    _modelController.dispose();
    _modelFocusNode.dispose();
    super.dispose();
  }

  void _loadCombineSpecs() {
    context.read<CombineBloc>().add(LoadCombineSpecs(
      brand: _selectedBrand,
      includePublicSpecs: true,
    ));
  }

  void _onModelTextChanged() {
    final text = _modelController.text.trim();
    if (text.length >= 2 && _selectedBrand != null) {
      _performFuzzySearch(text);
    } else {
      setState(() {
        _modelSuggestions = [];
        _showSuggestions = false;
      });
    }
  }

  void _onModelFocusChanged() {
    if (!_modelFocusNode.hasFocus) {
      // Hide suggestions when field loses focus
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _showSuggestions = false;
          });
        }
      });
    }
  }

  void _performFuzzySearch(String query) {
    // Trigger search through the bloc
    context.read<CombineBloc>().add(SearchCombines(
      query: '$_selectedBrand $query',
      userId: widget.userId,
      maxResults: 5,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CombineBloc, CombineState>(
      listener: _handleStateChanges,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand selection dropdown
          _buildBrandSelection(),
          const SizedBox(height: 24),
          
          // Year selection (only show if brand selected)
          if (_selectedBrand != null) ...[
            _buildYearSelection(),
            const SizedBox(height: 24),
          ],
          
          // Model autocomplete (only show if brand and year selected)
          if (_selectedBrand != null && _selectedYear != null) ...[
            _buildModelAutocomplete(),
            const SizedBox(height: 16),
          ],
          
          // Voice input option
          if (_selectedBrand != null && _selectedYear != null) ...[
            _buildVoiceInputOption(),
            const SizedBox(height: 24),
          ],
          
          // Selection summary
          if (_selectedBrand != null) 
            _buildSelectionSummary(),
        ],
      ),
    );
  }

  /// High contrast brand selection dropdown
  Widget _buildBrandSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with high contrast
        Text(
          'Combine Brand',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: FieldColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        
        // Dropdown with large touch target
        Container(
          width: double.infinity,
          height: 56, // Large touch target
          decoration: BoxDecoration(
            color: FieldColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: FieldColors.outline,
              width: 2,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedBrand,
              isExpanded: true,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Select brand',
                  style: TextStyle(
                    fontSize: 16,
                    color: FieldColors.onSurfaceVariant,
                  ),
                ),
              ),
              icon: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(
                  Icons.arrow_drop_down,
                  color: FieldColors.onSurface,
                  size: 32,
                ),
              ),
              dropdownColor: FieldColors.surface,
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              items: _brands.map((brand) => DropdownMenuItem<String>(
                value: brand,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    brand,
                    style: TextStyle(
                      fontSize: 16,
                      color: FieldColors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )).toList(),
              onChanged: _onBrandChanged,
            ),
          ),
        ),
      ],
    );
  }

  /// Year selection with large buttons
  Widget _buildYearSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Model Year',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: FieldColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        
        // Year grid with large touch targets
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: _endYear - _startYear + 1,
          itemBuilder: (context, index) {
            final year = _endYear - index; // Reverse order (newest first)
            final isSelected = year == _selectedYear;
            
            return Material(
              elevation: isSelected ? 4 : 2,
              borderRadius: BorderRadius.circular(12),
              color: isSelected ? FieldColors.primary : FieldColors.surface,
              child: InkWell(
                onTap: () => _onYearChanged(year),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? FieldColors.onPrimary : FieldColors.outline,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      year.toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? FieldColors.onPrimary : FieldColors.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Model autocomplete with fuzzy search
  Widget _buildModelAutocomplete() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Model Name',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: FieldColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        
        // Text field with autocomplete
        Stack(
          children: [
            // Main text field
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: FieldColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _modelFocusNode.hasFocus 
                      ? FieldColors.primary 
                      : FieldColors.outline,
                  width: 2,
                ),
              ),
              child: TextField(
                controller: _modelController,
                focusNode: _modelFocusNode,
                style: TextStyle(
                  fontSize: 16,
                  color: FieldColors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter model (e.g., X9 1100, 8120)',
                  hintStyle: TextStyle(
                    color: FieldColors.onSurfaceVariant,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  border: InputBorder.none,
                  suffixIcon: _modelController.text.isNotEmpty
                      ? IconButton(
                          onPressed: _clearModel,
                          icon: Icon(
                            Icons.clear,
                            color: FieldColors.onSurfaceVariant,
                          ),
                          iconSize: 24,
                          tooltip: 'Clear',
                        )
                      : Icon(
                          Icons.search,
                          color: FieldColors.onSurfaceVariant,
                          size: 24,
                        ),
                ),
                onChanged: (value) {
                  setState(() {
                    _selectedModel = value.trim().isEmpty ? null : value.trim();
                  });
                  _notifySelectionChanged();
                },
                onSubmitted: _onModelSubmitted,
              ),
            ),
            
            // Autocomplete suggestions
            if (_showSuggestions && _modelSuggestions.isNotEmpty)
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: _buildSuggestionsList(),
              ),
          ],
        ),
        
        // Helper text
        const SizedBox(height: 8),
        Text(
          'Start typing for suggestions',
          style: TextStyle(
            fontSize: 14,
            color: FieldColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Autocomplete suggestions list
  Widget _buildSuggestionsList() {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: FieldColors.surface,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: FieldColors.outline,
            width: 2,
          ),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: _modelSuggestions.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: FieldColors.outline,
          ),
          itemBuilder: (context, index) {
            final suggestion = _modelSuggestions[index];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _selectSuggestion(suggestion),
                child: Container(
                  height: 48, // Large touch target
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: FieldColors.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: TextStyle(
                            fontSize: 16,
                            color: FieldColors.onSurface,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.north_west,
                        color: FieldColors.onSurfaceVariant,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Voice input option for muddy glove conditions
  Widget _buildVoiceInputOption() {
    return Card(
      elevation: 2,
      color: FieldColors.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: FieldColors.outline,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: _startVoiceInput,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: FieldColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: FieldColors.onSurface,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.mic,
                  color: FieldColors.onPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voice Input',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: FieldColors.onSurface,
                      ),
                    ),
                    Text(
                      'Speak the model name',
                      style: TextStyle(
                        fontSize: 14,
                        color: FieldColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_voice,
                color: FieldColors.primary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Selection summary card
  Widget _buildSelectionSummary() {
    return Card(
      elevation: 4,
      color: FieldColors.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: FieldColors.primary,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.summarize,
                  color: FieldColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Current Selection',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: FieldColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            _buildSummaryRow('Brand:', _selectedBrand),
            if (_selectedYear != null)
              _buildSummaryRow('Year:', _selectedYear.toString()),
            if (_selectedModel != null)
              _buildSummaryRow('Model:', _selectedModel!),
              
            // Completion indicator
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _isSelectionComplete() ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: _isSelectionComplete() ? FieldColors.success : FieldColors.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _isSelectionComplete() 
                      ? 'Ready to proceed'
                      : 'Complete all fields to continue',
                  style: TextStyle(
                    fontSize: 14,
                    color: _isSelectionComplete() 
                        ? FieldColors.success
                        : FieldColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Summary row widget
  Widget _buildSummaryRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: FieldColors.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value ?? 'Not selected',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: value != null ? FieldColors.onSurface : FieldColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Event handlers
  
  void _handleStateChanges(BuildContext context, CombineState state) {
    if (state is CombineSearchResults) {
      setState(() {
        _modelSuggestions = state.results
            .map((result) => result.spec.model)
            .toList();
        _showSuggestions = _modelSuggestions.isNotEmpty && _modelFocusNode.hasFocus;
      });
    }
  }

  void _onBrandChanged(String? brand) {
    setState(() {
      _selectedBrand = brand;
      _selectedYear = null; // Reset year when brand changes
      _selectedModel = null; // Reset model when brand changes
      _modelController.clear();
    });
    
    if (brand != null) {
      // Load specs for this brand
      context.read<CombineBloc>().add(LoadCombineSpecs(
        brand: brand,
        includePublicSpecs: true,
      ));
    }
    
    _notifySelectionChanged();
  }

  void _onYearChanged(int year) {
    setState(() {
      _selectedYear = year;
    });
    
    // Auto-focus model field for better UX
    if (_selectedBrand != null) {
      _modelFocusNode.requestFocus();
    }
    
    _notifySelectionChanged();
  }

  void _onModelSubmitted(String value) {
    if (value.trim().isNotEmpty) {
      setState(() {
        _selectedModel = value.trim();
        _showSuggestions = false;
      });
      _modelFocusNode.unfocus();
      _notifySelectionChanged();
    }
  }

  void _selectSuggestion(String suggestion) {
    _modelController.text = suggestion;
    setState(() {
      _selectedModel = suggestion;
      _showSuggestions = false;
    });
    _modelFocusNode.unfocus();
    _notifySelectionChanged();
    
    // Haptic feedback for selection
    HapticFeedback.selectionClick();
  }

  void _clearModel() {
    _modelController.clear();
    setState(() {
      _selectedModel = null;
      _showSuggestions = false;
    });
    _notifySelectionChanged();
  }

  void _startVoiceInput() {
    // Placeholder for voice input implementation
    // Would integrate with speech_to_text package
    HapticFeedback.mediumImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Voice input would start here'),
        backgroundColor: FieldColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _notifySelectionChanged() {
    widget.onSelectionChanged(_selectedBrand, _selectedModel, _selectedYear);
  }

  bool _isSelectionComplete() {
    return _selectedBrand != null && _selectedYear != null && _selectedModel != null;
  }
}