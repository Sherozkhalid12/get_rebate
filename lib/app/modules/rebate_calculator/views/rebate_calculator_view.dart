// lib/app/modules/rebate_calculator/views/rebate_calculator_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/rebate_calculator/controllers/rebate_calculator_controller.dart';
import 'package:getrebate/app/widgets/custom_text_field.dart';
import 'package:getrebate/app/widgets/custom_button.dart';
import 'package:getrebate/app/services/rebate_calculator_api_service.dart';

class RebateCalculatorView extends StatelessWidget {
  const RebateCalculatorView({super.key});

  @override
  Widget build(BuildContext context) {
    // Auto-inject controller
    final controller = Get.put(RebateCalculatorController());

    // Read mode from bottom sheet
    final args = Get.arguments;
    if (args != null && args['mode'] is int) {
      controller.currentMode.value = args['mode'] as int;
    }

    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, controller),
            _buildModeTabs(context, controller),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildFullForm(context, controller),
                    const SizedBox(height: 20),
                    Obx(() => _buildResults(context, controller)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HEADER
  Widget _buildHeader(BuildContext context, RebateCalculatorController c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(
            child: Text(
              'Rebate Calculator',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            onPressed: c.resetAll,
            icon: const Icon(Icons.refresh, color: AppTheme.primaryBlue),
          ),
        ],
      ),
    );
  }

  // TABS
  Widget _buildModeTabs(BuildContext context, RebateCalculatorController c) {
    return Container(
      margin: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Obx(
        () => Row(
          children: [
            _tab(context, c, 'Estimated', 0),
            _tab(context, c, 'Actual', 1),
            _tab(context, c, 'Seller Conversion', 2),
          ],
        ),
      ),
    );
  }

  Widget _tab(
    BuildContext context,
    RebateCalculatorController c,
    String label,
    int idx,
  ) {
    final active = c.currentMode.value == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => c.setMode(idx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active ? AppTheme.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.white : AppTheme.darkGray,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullForm(BuildContext context, RebateCalculatorController c) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Property & Commission',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),

            CustomTextField(
              controller: c.homePriceController,
              labelText: 'Sales Price',
              prefixIcon: Icons.home,
            ),

            const SizedBox(height: 20),
            _dropdown(
              context,
              'State',
              c.selectedState,
              c.allowedStates,
              c.setSelectedState,
            ),
            const SizedBox(height: 8),
            Obx(() {
              if (c.isStateRestricted) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          c.getStateRestrictionMessage(c.selectedState),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            Obx(() {
              if (!c.shouldShowSellerRestriction) {
                return const SizedBox.shrink();
              }
              final message = c.getSellerRestrictionMessage();
              if (message.isEmpty) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.lightBlue),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppTheme.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),
            Text('Commission', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Obx(() {
              // For sellers (mode 2), show LAC field
              if (c.currentMode.value == 2) {
                return Column(
                  children: [
                    CustomTextField(
                      controller: c.sellerOriginalFeeController,
                      labelText: 'Listing Agent Commission (LAC) %',
                      prefixIcon: Icons.percent,
                      hintText: 'e.g. 2.5, 3.0',
                    ),
                  ],
                );
              }
              // For buyers (modes 0 and 1), show BAC field
              return CustomTextField(
                controller: c.agentCommissionController,
                labelText: 'Buyer Agent Commission (BAC) %',
                prefixIcon: Icons.percent,
                hintText: 'e.g. 2.5, 3.0',
              );
            }),

            const SizedBox(height: 20),
            _buildCommissionTierReference(context),

            const SizedBox(height: 16),
            _buildRebateInfoNote(context),

            const SizedBox(height: 24),
            // Convert/Calculate Button
            Obx(() => _buildConvertButton(context, c)),
          ],
        ),
      ),
    );
  }

  Widget _buildConvertButton(
    BuildContext context,
    RebateCalculatorController c,
  ) {
    final isLoading = c.isLoading;
    final isFormValid = c.isFormValid;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (isFormValid && !isLoading)
            ? () {
                switch (c.currentMode.value) {
                  case 0:
                    c.calculateEstimated();
                    break;
                  case 1:
                    c.calculateActual();
                    break;
                  case 2:
                    c.calculateSeller();
                    break;
                }
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Convert',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
      ),
    );
  }

  Widget _dropdown(
    BuildContext context,
    String label,
    String value,
    List<String> items,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) => v != null ? onChanged(v) : null,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.location_on, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildCommissionTierReference(BuildContext context) {
    return ExpansionTile(
      title: const Text('Commission Tier Reference'),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.lightGray,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tierRow(
                context,
                'Tier 1: 4.0% or more',
                '40% rebate',
                AppTheme.lightGreen,
              ),
              _tierRow(
                context,
                'Tier 2: 3.01% - 3.99%',
                '35% rebate',
                AppTheme.lightBlue,
              ),
              _tierRow(
                context,
                'Tier 3: 2.5% - 3.0%',
                '30% rebate',
                AppTheme.mediumGray,
              ),
              _tierRow(
                context,
                'Tier 4: 2.0% - 2.49%',
                '25% rebate',
                AppTheme.mediumGray,
              ),
              _tierRow(
                context,
                'Tier 5: 1.5% - 1.99%',
                '20% rebate',
                AppTheme.mediumGray,
              ),
              _tierRow(
                context,
                'Tier 6: .25% - 1.49%',
                '10% rebate',
                AppTheme.mediumGray,
              ),
              _tierRow(
                context,
                'Tier 7: 0 - .24%',
                '0% rebate',
                AppTheme.mediumGray,
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Note: For homes \$700,000 or higher, Tiers 5 and 6 do not apply. The minimum rebate will be Tier 4 (25%).',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.darkGray,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRebateInfoNote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.yellow.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: const Text(
        'Your rebate is based on the commission your agent (from this site) negotiates with the seller, listing agent, or builder. Real estate commissions are 100% negotiable.',
        style: TextStyle(fontSize: 12, color: Colors.black87),
      ),
    );
  }

  Widget _tierRow(
    BuildContext context,
    String range,
    String rebate,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(range),
          Text(
            rebate,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // RESULTS
  Widget _buildResults(BuildContext context, RebateCalculatorController c) {
    // Show API results if available, otherwise show local calculations
    final apiResult = c.currentApiResult;
    
    if (apiResult != null && apiResult.success) {
      return _buildApiResults(context, c, apiResult);
    }

    // Fallback to local calculations
    if (c.estimatedRebate.value <= 0 && c.currentMode.value != 0) {
      return _emptyState(context, "Enter details to calculate");
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              c.currentMode.value == 0
                  ? 'Rebate Tiers'
                  : c.currentMode.value == 1
                  ? 'Your Rebate'
                  : 'Commission Converted to Lower % Fee',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),

            // State restriction warning in results
            Obx(() {
              if (c.isStateRestricted) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.shade300,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.block,
                                color: Colors.red.shade700,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Rebates Not Available in ${c.selectedState}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.red.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            c.getStateRestrictionMessage(c.selectedState),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'The calculations shown are for informational purposes only and may not apply in your state. Please consult with a licensed real estate professional in your area.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black87,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }
              return const SizedBox.shrink();
            }),

            // MODE 0: Tiers
            if (c.currentMode.value == 0) ...[
              // Show threshold warning if home price >= 700k
              if ((double.tryParse(c.homePriceController.text) ?? 0.0) >=
                  700000)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'For homes \$700,000+: Tiers 5 & 6 do not apply. Minimum is Tier 4.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ...c.tiers.map(
                (t) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          t['range'],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          t['rebate'],
                          style: TextStyle(color: t['color'], fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '\$${t['amount']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // MODE 1: Actual
            if (c.currentMode.value == 1) ...[
              _resultItem(
                context,
                'Rebate',
                '\$${c.actualRebate.toStringAsFixed(0)}',
                AppTheme.lightGreen,
              ),
              _resultItem(
                context,
                'Tier',
                c.actualTier.value,
                AppTheme.primaryBlue,
              ),
            ],

            // MODE 2: Seller
            if (c.currentMode.value == 2) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'This shows the lower listing agent commission (LAC) percentage when the rebate is applied directly to the listing agent commission.',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
              _resultItem(
                context,
                'Original Listing Agent Commission (LAC)',
                '${c.sellerOriginalFeeController.text}%',
                AppTheme.mediumGray,
              ),
              _resultItem(
                context,
                'Rebate Amount',
                '\$${c.sellerRebate.toStringAsFixed(0)}',
                AppTheme.lightGreen,
              ),
              const Divider(height: 24),
              _resultItem(
                context,
                'New Listing Agent Commission (LAC)',
                '${c.sellerNewFee.toStringAsFixed(2)}%',
                AppTheme.primaryBlue,
                bold: true,
              ),
            ],

            const SizedBox(height: 20),
            CustomButton(text: 'Find Agents', onPressed: () {}),
          ],
        ),
      ),
    );
  }

  Widget _resultItem(
    BuildContext context,
    String label,
    String value,
    Color color, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              fontSize: bold ? 20 : 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context, String msg) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.calculate, size: 48, color: AppTheme.mediumGray),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.mediumGray),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds API results display
  Widget _buildApiResults(
    BuildContext context,
    RebateCalculatorController c,
    RebateCalculatorResponse result,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              c.currentMode.value == 0
                  ? 'Estimated Rebate Results'
                  : c.currentMode.value == 1
                  ? 'Exact Rebate Results'
                  : 'Seller Conversion Results',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 20),

            // Tier
            if (result.tier != null && result.tier!.isNotEmpty)
              _buildResultRow(
                context,
                'Tier',
                result.tier!,
                AppTheme.primaryBlue,
              ),

            // Rebate Percentage
            if (result.rebatePercentage != null)
              _buildResultRow(
                context,
                'Rebate Percentage',
                '${result.rebatePercentage!.toStringAsFixed(1)}%',
                AppTheme.lightGreen,
              ),

            // Estimated Rebate Range
            if (result.minRebate != null && result.maxRebate != null)
              _buildResultRow(
                context,
                'Estimated Rebate Range',
                _formatCurrencyRange(result.minRebate!, result.maxRebate!),
                AppTheme.lightGreen,
                isBold: true,
              )
            else if (result.minRebate != null)
              _buildResultRow(
                context,
                'Rebate Amount',
                _formatCurrency(result.minRebate!),
                AppTheme.lightGreen,
                isBold: true,
              ),

            // Commission Range for Tier
            if (result.minCommission != null && result.maxCommission != null)
              _buildResultRow(
                context,
                'Commission Range for Tier',
                '${result.minCommission!.toStringAsFixed(2)}% – ${result.maxCommission!.toStringAsFixed(2)}%',
                AppTheme.mediumGray,
              ),

            // Notes
            if (result.notes != null && result.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: Text(
                  'Notes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.darkGray,
                      ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: result.notes!.map((note) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            note,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.mediumGray,
                                ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],

            // Warnings
            if (result.warnings != null && result.warnings!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.shade300,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Warnings',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...result.warnings!.map((warning) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 6,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                warning,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.orange.shade900,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            CustomButton(text: 'Find Agents', onPressed: () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(
    BuildContext context,
    String label,
    String value,
    Color color, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
                    color: AppTheme.darkGray,
                  ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: color,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                    fontSize: isBold ? 18 : 16,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  String _formatCurrencyRange(double min, double max) {
    return '${_formatCurrency(min)} – ${_formatCurrency(max)}';
  }
}
