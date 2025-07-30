/**
 * Combine Capability Card - Displays combine specifications and capabilities
 * Optimized for farm field conditions with visual clarity over aesthetic complexity
 * 
 * Features:
 * - Moisture tolerance with visual indicators
 * - Tough crop ability with rating system
 * - Performance metrics with color-coded indicators
 * - Progressive data disclosure based on confidence levels
 * - High contrast design for sunlight readability
 * - Large touch targets for detailed views
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/combine_models.dart';
import '../../domain/models/common_types.dart';
import '../pages/combine_setup_page.dart';

/// Capability level enum for rating system
enum CapabilityLevel { excellent, good, average, poor, rich, moderate, basic }

class CombineCapabilityCard extends StatefulWidget {
  final CombineSpec combineSpec;
  final ProgressiveCapabilities? progressiveCapabilities;
  final bool isExpanded;
  final VoidCallback? onTap;
  final VoidCallback? onExpandToggle;
  
  const CombineCapabilityCard({
    super.key,
    required this.combineSpec,
    this.progressiveCapabilities,
    this.isExpanded = false,
    this.onTap,
    this.onExpandToggle,
  });

  @override
  State<CombineCapabilityCard> createState() => _CombineCapabilityCardState();
}

class _CombineCapabilityCardState extends State<CombineCapabilityCard>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
    
    if (widget.isExpanded) {
      _expandController.forward();
    }
  }

  @override
  void didUpdateWidget(CombineCapabilityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: FieldColors.surface,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: FieldColors.outline,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildBasicCapabilities(),
            AnimatedBuilder(
              animation: _expandAnimation,
              builder: (context, child) {
                return SizeTransition(
                  sizeFactor: _expandAnimation,
                  child: child,
                );
              },
              child: _buildExpandedContent(),
            ),
          ],
        ),
      ),
    );
  }

  /// Card header with combine info and expand button
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FieldColors.primary.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(
          bottom: BorderSide(
            color: FieldColors.outline,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Combine icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: FieldColors.primary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: FieldColors.onSurface,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.agriculture,
              color: FieldColors.onPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          
          // Combine details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.combineSpec.brand} ${widget.combineSpec.model}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: FieldColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (widget.combineSpec.year != null) ...[
                      Text(
                        '${widget.combineSpec.year}',
                        style: TextStyle(
                          fontSize: 14,
                          color: FieldColors.onSurfaceVariant,
                        ),
                      ),
                      Text(' • ', style: TextStyle(color: FieldColors.onSurfaceVariant)),
                    ],
                    _buildDataQualityBadge(),
                  ],
                ),
              ],
            ),
          ),
          
          // Expand/collapse button
          if (widget.onExpandToggle != null)
            IconButton(
              onPressed: () {
                widget.onExpandToggle?.call();
                HapticFeedback.selectionClick();
              },
              icon: AnimatedRotation(
                turns: widget.isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                child: const Icon(Icons.expand_more),
              ),
              iconSize: 28,
              color: FieldColors.primary,
              tooltip: widget.isExpanded ? 'Show less' : 'Show more',
              style: IconButton.styleFrom(
                backgroundColor: FieldColors.surface,
                shape: const CircleBorder(),
              ),
            ),
        ],
      ),
    );
  }

  /// Data quality badge
  Widget _buildDataQualityBadge() {
    final capabilities = widget.progressiveCapabilities;
    if (capabilities == null) {
      return _buildBadge('Basic Data', FieldColors.outline, FieldColors.onSurface);
    }
    
    final userCount = capabilities.userCount;
    final confidence = capabilities.dataConfidence;
    
    Color badgeColor;
    String badgeText;
    Color textColor;
    
    if (userCount >= 15 && confidence >= 0.8) {
      badgeColor = FieldColors.success;
      badgeText = 'High Quality';
      textColor = FieldColors.onSuccess;
    } else if (userCount >= 5 && confidence >= 0.6) {
      badgeColor = FieldColors.warning;
      badgeText = 'Good Data';
      textColor = FieldColors.onSurface;
    } else {
      badgeColor = FieldColors.outline;
      badgeText = 'Limited Data';
      textColor = FieldColors.onSurface;
    }
    
    return _buildBadge(badgeText, badgeColor, textColor);
  }

  /// Basic capabilities always visible
  Widget _buildBasicCapabilities() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick stats row
          Row(
            children: [
              Expanded(
                child: _buildQuickStat(
                  'Moisture Range',
                  '${widget.combineSpec.moistureTolerance.min.toInt()}% - ${widget.combineSpec.moistureTolerance.max.toInt()}%',
                  Icons.water_drop,
                  _getMoistureColor(widget.combineSpec.moistureTolerance),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickStat(
                  'Tough Crop Rating',
                  '${widget.combineSpec.toughCropAbility.rating}/10',
                  Icons.grass,
                  _getToughCropColor(widget.combineSpec.toughCropAbility.rating),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Capabilities at a glance
          _buildCapabilityIndicators(),
        ],
      ),
    );
  }

  /// Quick stat widget
  Widget _buildQuickStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: FieldColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Capability indicators with icons
  Widget _buildCapabilityIndicators() {
    final toughCrop = widget.combineSpec.toughCropAbility;
    
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        if (toughCrop.handlesHighMoisture)
          _buildIndicatorChip('High Moisture', Icons.water, FieldColors.primary),
        if (toughCrop.handlesLodgedCrops)
          _buildIndicatorChip('Lodged Crops', Icons.grass, FieldColors.success),
        if (toughCrop.handlesGreenStem)
          _buildIndicatorChip('Green Stem', Icons.eco, FieldColors.success),
        if (widget.combineSpec.harvestCapabilities?.hasYieldMapping == true)
          _buildIndicatorChip('Yield Mapping', Icons.map, FieldColors.primary),
        if (widget.combineSpec.harvestCapabilities?.hasMoistureMapping == true)
          _buildIndicatorChip('Moisture Mapping', Icons.device_thermostat, FieldColors.primary),
      ],
    );
  }

  /// Indicator chip
  Widget _buildIndicatorChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Expanded content with detailed information
  Widget _buildExpandedContent() {
    return Column(
      children: [
        _buildDetailedMoistureInfo(),
        _buildDetailedToughCropInfo(),
        if (widget.combineSpec.harvestCapabilities != null)
          _buildHarvestCapabilities(),
        if (widget.progressiveCapabilities != null)
          _buildProgressiveInsights(),
        _buildSourceInformation(),
      ],
    );
  }

  /// Detailed moisture tolerance information
  Widget _buildDetailedMoistureInfo() {
    final moisture = widget.combineSpec.moistureTolerance;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FieldColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FieldColors.outline,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.water_drop,
                color: _getMoistureColor(moisture),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Moisture Tolerance Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: FieldColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Moisture range visualization
          _buildMoistureRangeBar(moisture),
          const SizedBox(height: 12),
          
          // Range details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMoisturePoint('Min', '${moisture.min.toInt()}%', FieldColors.error),
              _buildMoisturePoint('Optimal', '${moisture.optimal.toInt()}%', FieldColors.success),
              _buildMoisturePoint('Max', '${moisture.max.toInt()}%', FieldColors.warning),
            ],
          ),
        ],
      ),
    );
  }

  /// Moisture range visualization bar
  Widget _buildMoistureRangeBar(MoistureTolerance moisture) {
    final totalRange = 30.0; // 0-30% moisture range for visualization
    final minPos = moisture.min / totalRange;
    final optimalPos = moisture.optimal / totalRange;
    final maxPos = moisture.max / totalRange;
    
    return Container(
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FieldColors.outline,
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              color: FieldColors.outline.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          
          // Operating range
          Positioned(
            left: minPos * MediaQuery.of(context).size.width * 0.7,
            right: (1 - maxPos) * MediaQuery.of(context).size.width * 0.7,
            top: 4,
            bottom: 4,
            child: Container(
              decoration: BoxDecoration(
                color: FieldColors.success.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          
          // Optimal point
          Positioned(
            left: optimalPos * MediaQuery.of(context).size.width * 0.7 - 2,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: FieldColors.success,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Moisture point indicator
  Widget _buildMoisturePoint(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: FieldColors.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Detailed tough crop information
  Widget _buildDetailedToughCropInfo() {
    final toughCrop = widget.combineSpec.toughCropAbility;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FieldColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FieldColors.outline,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.grass,
                color: _getToughCropColor(toughCrop.rating),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Tough Crop Performance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: FieldColors.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getToughCropColor(toughCrop.rating),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${toughCrop.rating}/10',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Supported crops
          if (toughCrop.crops.isNotEmpty) ...[
            Text(
              'Supported Crops:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: FieldColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: toughCrop.crops.map((crop) => Chip(
                label: Text(
                  crop.toUpperCase(),
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: FieldColors.primary.withOpacity(0.1),
                side: BorderSide(color: FieldColors.primary, width: 1),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )).toList(),
            ),
          ],
          
          // Limitations
          if (toughCrop.limitations.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Limitations:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: FieldColors.error,
              ),
            ),
            const SizedBox(height: 4),
            ...toughCrop.limitations.map((limitation) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning,
                    color: FieldColors.warning,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      limitation,
                      style: TextStyle(
                        fontSize: 13,
                        color: FieldColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  /// Harvest capabilities section
  Widget _buildHarvestCapabilities() {
    final harvest = widget.combineSpec.harvestCapabilities!;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FieldColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FieldColors.outline,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.speed,
                color: FieldColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Performance Specifications',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: FieldColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Performance metrics grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _buildPerformanceMetric('Operating Speed', '${harvest.operatingSpeedKmh} km/h', Icons.speed),
              _buildPerformanceMetric('Tank Capacity', '${(harvest.grainTankCapacityL / 1000).toInt()}k L', Icons.local_gas_station),
              _buildPerformanceMetric('Daily Capacity', '${harvest.dailyCapacityHa.toInt()} ha', Icons.calendar_today),
              _buildPerformanceMetric('Fuel Usage', '${harvest.fuelConsumptionLh.toInt()} L/h', Icons.oil_barrel),
            ],
          ),
        ],
      ),
    );
  }

  /// Performance metric widget
  Widget _buildPerformanceMetric(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FieldColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: FieldColors.outline,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: FieldColors.primary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: FieldColors.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: FieldColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// Progressive insights based on user data
  Widget _buildProgressiveInsights() {
    final progressive = widget.progressiveCapabilities!;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FieldColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FieldColors.primary,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights,
                color: FieldColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Farmer Insights',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: FieldColors.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '${progressive.userCount} farmers',
                style: TextStyle(
                  fontSize: 12,
                  color: FieldColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Text(
            'Based on real-world data from ${progressive.userCount} farmers using this combine model.',
            style: TextStyle(
              fontSize: 14,
              color: FieldColors.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          
          // Show progressive data based on availability level
          if (progressive.level == CapabilityLevel.rich) ...[
            const SizedBox(height: 12),
            Text(
              'Rich data available with detailed performance comparisons and expert recommendations.',
              style: TextStyle(
                fontSize: 13,
                color: FieldColors.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else if (progressive.level == CapabilityLevel.moderate) ...[
            const SizedBox(height: 12),
            Text(
              'Good data available with brand-specific insights and common usage patterns.',
              style: TextStyle(
                fontSize: 13,
                color: FieldColors.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Source information
  Widget _buildSourceInformation() {
    final source = widget.combineSpec.sourceData;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FieldColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FieldColors.outline,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Sources',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: FieldColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              _buildSourceIndicator('User Reports', source.userReports.toString(), source.userReports > 0),
              const SizedBox(width: 16),
              _buildSourceIndicator('Manufacturer', 'Specs', source.manufacturerSpecs),
              const SizedBox(width: 16),
              _buildSourceIndicator('Expert', 'Validated', source.expertValidation),
            ],
          ),
          
          const SizedBox(height: 8),
          Text(
            'Last updated: ${_formatDate(source.lastUpdated)}',
            style: TextStyle(
              fontSize: 12,
              color: FieldColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Source indicator
  Widget _buildSourceIndicator(String label, String value, bool isAvailable) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isAvailable ? Icons.check_circle : Icons.cancel,
          color: isAvailable ? FieldColors.success : FieldColors.outline,
          size: 16,
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: FieldColors.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isAvailable ? FieldColors.onSurface : FieldColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Helper methods
  
  Widget _buildBadge(String text, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FieldColors.onSurface,
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Color _getMoistureColor(MoistureTolerance moisture) {
    final range = moisture.max - moisture.min;
    if (range >= 8) return FieldColors.success; // Wide tolerance
    if (range >= 5) return FieldColors.warning; // Medium tolerance
    return FieldColors.error; // Narrow tolerance
  }

  Color _getToughCropColor(int rating) {
    if (rating >= 8) return FieldColors.success;
    if (rating >= 6) return FieldColors.warning;
    return FieldColors.error;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 1) {
      return 'Today';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}