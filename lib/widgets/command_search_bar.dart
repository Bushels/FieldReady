/**
 * Command palette style search bar for FieldReady combine selection
 * Features fuzzy search, suggestions, and smooth animations
 */

import 'package:flutter/material.dart';
import 'dart:async';
import '../data/combine_data.dart';
import '../utils/fuzzy_search.dart';

class CommandSearchBar extends StatefulWidget {
  final Function(String) onSearchChanged;
  final VoidCallback? onClear;
  final String? hintText;
  final bool autofocus;
  final List<CombineData> combines;

  const CommandSearchBar({
    super.key,
    required this.onSearchChanged,
    this.onClear,
    this.hintText,
    this.autofocus = true,
    required this.combines,
  });

  @override
  State<CommandSearchBar> createState() => _CommandSearchBarState();
}

class _CommandSearchBarState extends State<CommandSearchBar>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _borderColorAnimation;
  
  Timer? _debounceTimer;
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _borderColorAnimation = ColorTween(
      begin: Colors.grey[300],
      end: Theme.of(context).colorScheme.primary,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _focusNode.addListener(_handleFocusChange);
    _controller.addListener(_handleTextChange);

    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    if (_isFocused) {
      _animationController.forward();
      if (_controller.text.isNotEmpty) {
        _updateSuggestions(_controller.text);
      }
    } else {
      _animationController.reverse();
      setState(() {
        _showSuggestions = false;
      });
    }
  }

  void _handleTextChange() {
    final text = _controller.text;
    
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    // Debounce search to avoid excessive API calls
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      widget.onSearchChanged(text);
      if (text.isNotEmpty && _isFocused) {
        _updateSuggestions(text);
      } else {
        setState(() {
          _showSuggestions = false;
        });
      }
    });
  }

  void _updateSuggestions(String query) {
    if (query.length >= 2) {
      final suggestions = FuzzySearch.getSuggestions(query, widget.combines);
      setState(() {
        _suggestions = suggestions;
        _showSuggestions = suggestions.isNotEmpty;
      });
    } else {
      setState(() {
        _showSuggestions = false;
      });
    }
  }

  void _selectSuggestion(String suggestion) {
    _controller.text = suggestion;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    setState(() {
      _showSuggestions = false;
    });
    widget.onSearchChanged(suggestion);
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {
      _showSuggestions = false;
    });
    widget.onSearchChanged('');
    widget.onClear?.call();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, _) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _borderColorAnimation.value ?? Colors.grey[300]!,
                    width: _isFocused ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(_isFocused ? 0.1 : 0.05),
                      blurRadius: _isFocused ? 8 : 4,
                      offset: Offset(0, _isFocused ? 4 : 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Icon(
                      Icons.search,
                      color: _isFocused ? colorScheme.primary : Colors.grey[600],
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: widget.hintText ?? 'Search combines...',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (value) {
                          if (_suggestions.isNotEmpty) {
                            _selectSuggestion(_suggestions.first);
                          }
                        },
                      ),
                    ),
                    if (_controller.text.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _clearSearch,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            );
          },
        ),
        if (_showSuggestions) ...[
          const SizedBox(height: 8),
          _buildSuggestions(),
        ],
      ],
    );
  }

  Widget _buildSuggestions() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = _suggestions[index];
            final isLast = index == _suggestions.length - 1;
            
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _selectSuggestion(suggestion),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: isLast 
                        ? null 
                        : Border(
                            bottom: BorderSide(
                              color: Colors.grey[100]!,
                              width: 1,
                            ),
                          ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.north_west,
                        size: 16,
                        color: Colors.grey[400],
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
}