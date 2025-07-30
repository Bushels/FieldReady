/**
 * Combine Confirmation Dialog - "Did you mean X?" dialog for uncertain matches
 * Optimized for farm field conditions with high contrast and large touch targets
 * 
 * Features:
 * - Clear visual hierarchy with confidence indicators
 * - Large touch targets (minimum 56dp) for gloved hands
 * - High contrast colors for sunlight readability
 * - Alternative suggestions with relevance scoring
 * - Manual entry fallback option
 * - Haptic feedback for selections
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/combine_models.dart';
import '../pages/combine_setup_page.dart';

/// Callback for when user confirms a match
typedef MatchConfirmedCallback = void Function(FuzzyMatchResult match);

/// Callback for when user rejects all matches
typedef MatchRejectedCallback = void Function(String? userCorrection);

class CombineConfirmationDialog extends StatefulWidget {
  final String originalInput;
  final List<FuzzyMatchResult> matchResults;
  final MatchConfirmedCallback onConfirmed;
  final MatchRejectedCallback onRejected;
  final VoidCallback? onManualEntry;
  
  const CombineConfirmationDialog({
    super.key,
    required this.originalInput,
    required this.matchResults,
    required this.onConfirmed,
    required this.onRejected,
    this.onManualEntry,
  });

  @override
  State<CombineConfirmationDialog> createState() => _CombineConfirmationDialogState();
}

class _CombineConfirmationDialogState extends State<CombineConfirmationDialog>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  final TextEditingController _correctionController = TextEditingController();
  bool _showManualEntry = false;
  FuzzyMatchResult? _selectedMatch;

  @override
  void initState() {
    super.initState();
    
    // Set up animations for smooth entrance
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    // Start entrance animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _correctionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: _buildDialogContent(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        maxWidth: 500,
        maxHeight: 600,
      ),
      decoration: BoxDecoration(
        color: FieldColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: FieldColors.outline,
          width: 3, // Thick border for high contrast
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          Flexible(
            child: _showManualEntry 
                ? _buildManualEntryContent()
                : _buildMatchesContent(),
          ),
          _buildActions(),
        ],
      ),
    );
  }

  /// Dialog header with title and close button
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: FieldColors.primary.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(
          bottom: BorderSide(
            color: FieldColors.outline,
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          // Question icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: FieldColors.warning,
              shape: BoxShape.circle,
              border: Border.all(
                color: FieldColors.onSurface,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.help_outline,
              color: FieldColors.onSurface,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          
          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _showManualEntry ? 'Enter Correct Model' : 'Did you mean?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: FieldColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _showManualEntry 
                      ? 'Type the exact model name'
                      : 'We found similar models for "${widget.originalInput}"',
                  style: TextStyle(
                    fontSize: 14,
                    color: FieldColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          // Close button
          IconButton(
            onPressed: _closeDialog,
            icon: const Icon(Icons.close),
            iconSize: 28,
            color: FieldColors.onSurfaceVariant,
            tooltip: 'Cancel',
            style: IconButton.styleFrom(
              backgroundColor: FieldColors.surfaceVariant,
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }

  /// Main content showing match results
  Widget _buildMatchesContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instruction text
          Text(
            'Select the correct combine model:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: FieldColors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          
          // Match options
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.matchResults.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final match = widget.matchResults[index];
                return _buildMatchOption(match);
              },
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Manual entry option
          _buildManualEntryTrigger(),
        ],
      ),
    );
  }

  /// Manual entry content
  Widget _buildManualEntryContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _showManualEntry = false;
                  });
                },
                icon: const Icon(Icons.arrow_back),
                iconSize: 24,
                color: FieldColors.primary,
                tooltip: 'Back to suggestions',
              ),
              Text(
                'Back to suggestions',
                style: TextStyle(
                  fontSize: 16,
                  color: FieldColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Manual entry field
          Text(
            'Enter the correct model name:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: FieldColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: FieldColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: FieldColors.primary,
                width: 2,
              ),
            ),
            child: TextField(
              controller: _correctionController,
              autofocus: true,
              style: TextStyle(
                fontSize: 16,
                color: FieldColors.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'e.g., X9 1100, 8120, CR10.90',
                hintStyle: TextStyle(
                  color: FieldColors.onSurfaceVariant,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _submitManualEntry(),
            ),
          ),
          const SizedBox(height: 12),
          
          Text(
            'This helps us improve our suggestions for other farmers.',
            style: TextStyle(
              fontSize: 14,
              color: FieldColors.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// Individual match option card
  Widget _buildMatchOption(FuzzyMatchResult match) {
    final isSelected = _selectedMatch == match;
    
    return Material(
      elevation: isSelected ? 6 : 3,
      borderRadius: BorderRadius.circular(12),
      color: isSelected ? FieldColors.primary.withOpacity(0.1) : FieldColors.surface,
      child: InkWell(
        onTap: () => _selectMatch(match),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? FieldColors.primary : FieldColors.outline,
              width: isSelected ? 3 : 2,
            ),
          ),
          child: Row(
            children: [
              // Selection indicator
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? FieldColors.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? FieldColors.primary : FieldColors.outline,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: FieldColors.onPrimary,
                        size: 16,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              
              // Match details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Model name
                    Text(
                      _formatModelName(match.canonical),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: FieldColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Match type description
                    Text(
                      _getMatchDescription(match),
                      style: TextStyle(
                        fontSize: 14,
                        color: FieldColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Confidence badge
              _buildConfidenceBadge(match.confidence),
            ],
          ),
        ),
      ),
    );
  }

  /// Confidence badge with color coding
  Widget _buildConfidenceBadge(double confidence) {
    Color badgeColor;
    String confidenceText;
    Color textColor;
    
    if (confidence >= 0.9) {
      badgeColor = FieldColors.success;
      confidenceText = 'HIGH';
      textColor = FieldColors.onSuccess;
    } else if (confidence >= 0.7) {
      badgeColor = FieldColors.warning;
      confidenceText = 'MEDIUM';
      textColor = FieldColors.onSurface;
    } else {
      badgeColor = FieldColors.error;
      confidenceText = 'LOW';
      textColor = FieldColors.onError;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: FieldColors.onSurface,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            confidenceText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            '${(confidence * 100).toInt()}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Manual entry trigger button
  Widget _buildManualEntryTrigger() {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      color: FieldColors.surfaceVariant,
      child: InkWell(
        onTap: () {
          setState(() {
            _showManualEntry = true;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: FieldColors.outline,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.edit,
                color: FieldColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'None of these match? Enter manually',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: FieldColors.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward,
                color: FieldColors.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Action buttons at bottom of dialog
  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: FieldColors.surfaceVariant.withOpacity(0.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(
            color: FieldColors.outline,
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          // Cancel button
          Expanded(
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _closeDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FieldColors.surfaceVariant,
                  foregroundColor: FieldColors.onSurfaceVariant,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: FieldColors.outline,
                      width: 2,
                    ),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Confirm button
          Expanded(
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _canConfirm() ? _confirmSelection : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FieldColors.primary,
                  foregroundColor: FieldColors.onPrimary,
                  elevation: 4,
                  disabledBackgroundColor: FieldColors.outline,
                  disabledForegroundColor: FieldColors.onSurfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: FieldColors.outline,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  _showManualEntry ? 'Submit' : 'Confirm',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Event handlers
  
  void _selectMatch(FuzzyMatchResult match) {
    setState(() {
      _selectedMatch = match;
    });
    
    // Haptic feedback for selection
    HapticFeedback.selectionClick();
  }

  void _confirmSelection() {
    if (_showManualEntry) {
      _submitManualEntry();
    } else if (_selectedMatch != null) {
      // Haptic feedback for confirmation
      HapticFeedback.mediumImpact();
      
      // Close dialog with animation
      _animationController.reverse().then((_) {
        if (mounted) {
          widget.onConfirmed(_selectedMatch!);
          Navigator.of(context).pop();
        }
      });
    }
  }

  void _submitManualEntry() {
    final correction = _correctionController.text.trim();
    if (correction.isNotEmpty) {
      // Haptic feedback
      HapticFeedback.mediumImpact();
      
      // Close dialog with animation
      _animationController.reverse().then((_) {
        if (mounted) {
          widget.onRejected(correction);
          Navigator.of(context).pop();
        }
      });
    }
  }

  void _closeDialog() {
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    _animationController.reverse().then((_) {
      if (mounted) {
        widget.onRejected(null);
        Navigator.of(context).pop();
      }
    });
  }

  /// Helper methods
  
  bool _canConfirm() {
    if (_showManualEntry) {
      return _correctionController.text.trim().isNotEmpty;
    } else {
      return _selectedMatch != null;
    }
  }

  String _formatModelName(String canonical) {
    // Convert canonical format (john_deere_x9_1100) to display format
    return canonical
        .split('_')
        .skip(1) // Skip brand name
        .map((part) => part.toUpperCase())
        .join(' ');
  }

  String _getMatchDescription(FuzzyMatchResult match) {
    switch (match.matchType) {
      case MatchType.exact:
        return 'Exact match';
      case MatchType.variant:
        return 'Model variant';
      case MatchType.fuzzy:
        return 'Similar model name';
      case MatchType.brandAlias:
        return 'Brand name variation';
    }
  }

  /// Static helper method to show dialog
  static Future<void> show({
    required BuildContext context,
    required String originalInput,
    required List<FuzzyMatchResult> matchResults,
    required MatchConfirmedCallback onConfirmed,
    required MatchRejectedCallback onRejected,
    VoidCallback? onManualEntry,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => CombineConfirmationDialog(
        originalInput: originalInput,
        matchResults: matchResults,
        onConfirmed: onConfirmed,
        onRejected: onRejected,
        onManualEntry: onManualEntry,
      ),
    );
  }
}