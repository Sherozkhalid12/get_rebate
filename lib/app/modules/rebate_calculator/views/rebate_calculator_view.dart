// lib/app/modules/rebate_calculator/views/rebate_calculator_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/controllers/auth_controller.dart';
import 'package:getrebate/app/models/user_model.dart';
import 'package:getrebate/app/modules/rebate_calculator/controllers/rebate_calculator_controller.dart';
import 'package:getrebate/app/widgets/custom_text_field.dart';
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
      final requestedMode = args['mode'] as int;
      if (controller.currentMode.value != requestedMode) {
        controller.setMode(requestedMode);
      }
    }
    final authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : null;
    final isAgentUser = authController?.currentUser?.role == UserRole.agent;
    final openedByAgentArg =
        args is Map<String, dynamic> && args['openedByAgent'] == true;
    final shouldShowFindAgentsButton = !(isAgentUser || openedByAgentArg);

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
                    GetBuilder<RebateCalculatorController>(
                      id: 'rebateResults',
                      init: controller,
                      builder: (c) {
                        final mode = c.currentMode.value;
                        final apiResult = mode == 0
                            ? c.apiResultEstimated.value
                            : mode == 1
                            ? c.apiResultActual.value
                            : c.apiResultSeller.value;
                        return _buildResults(
                          context,
                          c,
                          mode: mode,
                          apiResult: apiResult,
                          shouldShowFindAgentsButton:
                              shouldShowFindAgentsButton,
                        );
                      },
                    ),
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
            onPressed: () => Navigator.pop(context),
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
        onTap: () {
          c.setMode(idx);
          if (idx != 0 && !_hasRequiredInputsForMode(c, idx)) {
            Get.snackbar(
              'Add price & commission',
              'Enter price and commission to see results instantly.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange.shade100,
              colorText: Colors.orange.shade900,
              duration: const Duration(seconds: 3),
            );
          }
        },
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
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
                LengthLimitingTextInputFormatter(12),
              ],
              hintText: 'e.g. 750,000',
            ),

            const SizedBox(height: 20),
            _dropdownStyled(
              context,
              'State',
              c.selectedState,
              c.allowedStates,
              c.setSelectedState,
            ),
            const SizedBox(height: 8),
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: false,
                      ),
                      inputFormatters: _percentFormatters,
                      onChanged: c.handleCommissionChanged,
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
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: false,
                ),
                inputFormatters: _percentFormatters,
                onChanged: c.handleCommissionChanged,
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
            ? () => c.calculateFromCurrentMode()
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
            ? SizedBox(
                height: 20,
                width: 20,
                child: SpinKitFadingCircle(color: Colors.white, size: 20),
              )
            : Text(
                'Calculate',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  List<TextInputFormatter> get _percentFormatters => [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
    LengthLimitingTextInputFormatter(5),
  ];

  Widget _dropdownStyled(
    BuildContext context,
    String label,
    String value,
    List<String> items,
    Function(String) onChanged,
  ) {
    final sorted = [...items]..sort();
    final safeValue = sorted.contains(value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: safeValue,
          isExpanded: true,
          menuMaxHeight: 320,
          dropdownColor: AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          elevation: 8,
          items: sorted
              .map(
                (s) => DropdownMenuItem<String>(
                  value: s,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          s,
                          style: const TextStyle(
                            color: AppTheme.darkGray,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => v != null ? onChanged(v) : null,
          selectedItemBuilder: (context) {
            // Prevent clipped text in the closed state by rendering a simple row
            return sorted
                .map(
                  (s) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      s,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.darkGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList();
          },
          decoration: InputDecoration(
            labelText: 'Select State',
            labelStyle: const TextStyle(
              color: AppTheme.mediumGray,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.only(left: 12, right: 8),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.map_outlined,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
            ),
            contentPadding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.primaryBlue.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
            ),
            filled: true,
            fillColor: AppTheme.primaryBlue.withOpacity(0.04),
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
  Widget _buildResults(
    BuildContext context,
    RebateCalculatorController c, {
    required int mode,
    required RebateCalculatorResponse? apiResult,
    required bool shouldShowFindAgentsButton,
  }) {
    // Only show API results - no instant/local calculations
    if (apiResult != null && apiResult.success) {
      return _buildApiResults(
        context,
        c,
        apiResult,
        mode: mode,
        shouldShowFindAgentsButton: shouldShowFindAgentsButton,
      );
    }

    // No API result yet - show empty state (API results only, no instant calc)
    return _emptyState(
      context,
      _hasRequiredInputsForMode(c, mode)
          ? 'Tap Calculate to see results'
          : 'Enter price, commission, and state to calculate',
      shouldShowFindAgentsButton: shouldShowFindAgentsButton,
    );
  }

  bool _hasRequiredInputsForCurrentMode(RebateCalculatorController c) {
    return _hasRequiredInputsForMode(c, c.currentMode.value);
  }

  bool _hasRequiredInputsForMode(RebateCalculatorController c, int mode) {
    final priceText = c.homePriceController.text.replaceAll(
      RegExp(r'[,\$]'),
      '',
    );
    final price = double.tryParse(priceText) ?? 0.0;

    final sellerCommission =
        double.tryParse(c.sellerOriginalFeeController.text) ?? 0.0;
    final buyerCommission =
        double.tryParse(c.agentCommissionController.text) ?? 0.0;
    final commission = mode == 2
        ? (sellerCommission > 0 ? sellerCommission : buyerCommission)
        : buyerCommission;

    return price > 0 && commission > 0;
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

  Widget _emptyState(
    BuildContext context,
    String msg, {
    bool shouldShowFindAgentsButton = false,
  }) {
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
            if (shouldShowFindAgentsButton) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Get.toNamed('/find-agents'),
                  icon: const Icon(Icons.search, size: 24),
                  label: const Text(
                    'Find Agents',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds API results display - tab-specific professional layout
  Widget _buildApiResults(
    BuildContext context,
    RebateCalculatorController c,
    RebateCalculatorResponse result, {
    required int mode,
    required bool shouldShowFindAgentsButton,
  }) {
    bool isOrMore = false;
    if (result.rawData != null) {
      final estimate = result.rawData!['estimate'];
      if (estimate is Map<String, dynamic>) {
        final range = estimate['estimatedRebateRange'];
        if (range is Map<String, dynamic>) {
          final max = range['max'];
          if (max != null && max.toString().toLowerCase().contains('more')) {
            isOrMore = true;
          }
        }
      }
    }

    final String headerTitle = mode == 0
        ? 'Estimated Rebate Results'
        : mode == 1
        ? 'Exact Rebate Results'
        : 'Seller Conversion Results';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, AppTheme.lightGray.withOpacity(0.2)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildResultsHeader(context, headerTitle),
              const SizedBox(height: 24),
              if (mode == 0)
                _buildEstimatedTabContent(context, result, isOrMore),
              if (mode == 1) _buildActualTabContent(context, result),
              if (mode == 2) _buildSellerTabContent(context, result),
              const SizedBox(height: 20),
              if (result.notes != null && result.notes!.isNotEmpty)
                _buildNotesSection(context, result.notes!),
              if (result.instructions != null &&
                  result.instructions!.isNotEmpty)
                _buildInstructionsSection(context, result.instructions!),
              if (result.warnings != null && result.warnings!.isNotEmpty)
                _buildWarningsSection(context, result.warnings!),

              if (shouldShowFindAgentsButton) ...[
                const SizedBox(height: 24),
                // Find Agents Button - Enhanced
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.toNamed('/find-agents');
                    },
                    icon: const Icon(Icons.search, size: 24),
                    label: const Text(
                      'Find Agents',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsHeader(BuildContext context, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.calculate_rounded,
            color: AppTheme.primaryBlue,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGray,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEstimatedTabContent(
    BuildContext context,
    RebateCalculatorResponse result,
    bool isOrMore,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightBlue.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.tier != null && result.tier!.isNotEmpty) ...[
            _buildTierBadge(context, result.tier!),
            const SizedBox(height: 20),
          ],
          if (result.rebatePercentage != null) ...[
            Text(
              'Rebate Percentage',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.mediumGray,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${result.rebatePercentage!.toStringAsFixed(0)}%',
              style: TextStyle(
                color: AppTheme.lightGreen,
                fontWeight: FontWeight.bold,
                fontSize: 34,
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (result.minRebate != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.lightGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.lightGreen.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated Rebate Range',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.darkGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isOrMore || result.maxRebate == null
                        ? '${_formatCurrency(result.minRebate!)} or more'
                        : _formatCurrencyRange(
                            result.minRebate!,
                            result.maxRebate!,
                          ),
                    style: TextStyle(
                      color: AppTheme.lightGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (result.minCommission != null)
            _buildResultRow(
              context,
              'Commission Range for Tier',
              result.maxCommission != null
                  ? '${result.minCommission!.toStringAsFixed(2)}% – ${result.maxCommission!.toStringAsFixed(2)}%'
                  : '${result.minCommission!.toStringAsFixed(2)}% or more',
              AppTheme.mediumGray,
            ),
        ],
      ),
    );
  }

  Widget _buildTierBadge(BuildContext context, String tier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryBlue, width: 2),
      ),
      child: Text(
        tier,
        style: TextStyle(
          color: AppTheme.primaryBlue,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildActualTabContent(
    BuildContext context,
    RebateCalculatorResponse result,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightBlue.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.tier != null && result.tier!.isNotEmpty) ...[
            _buildTierBadge(context, result.tier!),
            const SizedBox(height: 20),
          ],
          if (result.rebatePercentage != null) ...[
            _buildResultRow(
              context,
              'Rebate Percentage',
              '${result.rebatePercentage!.toStringAsFixed(0)}%',
              AppTheme.lightGreen,
            ),
            const SizedBox(height: 12),
          ],
          if (result.rebateAmountFormatted != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.lightGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.lightGreen.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Rebate Amount',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkGray,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _ensureCurrencyFormat(result.rebateAmountFormatted!),
                      style: const TextStyle(
                        color: AppTheme.lightGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (result.totalCommissionFormatted != null)
            _buildResultRow(
              context,
              'Total Commission',
              _ensureCurrencyFormat(result.totalCommissionFormatted!),
              AppTheme.mediumGray,
            ),
          if (result.netAgentCommissionFormatted != null)
            _buildResultRow(
              context,
              'Net Agent Commission',
              _ensureCurrencyFormat(result.netAgentCommissionFormatted!),
              AppTheme.primaryBlue,
              isBold: true,
            ),
        ],
      ),
    );
  }

  Widget _buildSellerTabContent(
    BuildContext context,
    RebateCalculatorResponse result,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightBlue.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result.tier != null && result.tier!.isNotEmpty) ...[
                _buildTierBadge(context, result.tier!),
                const SizedBox(height: 20),
              ],
              if (result.rebatePercentage != null)
                _buildResultRow(
                  context,
                  'Rebate Percentage',
                  '${result.rebatePercentage!.toStringAsFixed(0)}%',
                  AppTheme.lightGreen,
                ),
              if (result.originalCommissionAmountFormatted != null)
                _buildResultRow(
                  context,
                  'Original Commission',
                  _ensureCurrencyFormat(
                    result.originalCommissionAmountFormatted!,
                  ),
                  AppTheme.mediumGray,
                ),
              if (result.newCommissionAmountFormatted != null)
                _buildResultRow(
                  context,
                  'New Commission Amount',
                  _ensureCurrencyFormat(result.newCommissionAmountFormatted!),
                  AppTheme.primaryBlue,
                ),
              if (result.sellerSavingsFormatted != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.lightGreen.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Savings',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.darkGray,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          _ensureCurrencyFormat(result.sellerSavingsFormatted!),
                          style: const TextStyle(
                            color: AppTheme.lightGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (result.effectiveCommissionRateFormatted != null)
                _buildResultRow(
                  context,
                  'Effective Commission Rate',
                  result.effectiveCommissionRateFormatted!.endsWith('%')
                      ? result.effectiveCommissionRateFormatted!
                      : '${result.effectiveCommissionRateFormatted}%',
                  AppTheme.primaryBlue,
                  isBold: true,
                ),
            ],
          ),
        ),
        if (result.listingFeeForContract != null ||
            result.simplifiedNote != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'For Your Listing Agreement',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 12),
                if (result.listingFeeForContract != null)
                  _buildResultRow(
                    context,
                    'Listing Fee',
                    result.listingFeeForContract!,
                    AppTheme.primaryBlue,
                    isBold: true,
                  ),
                if (result.simplifiedNote != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    result.simplifiedNote!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.darkGray,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (result.simplifiedInstructions != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    result.simplifiedInstructions!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.mediumGray,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _ensureCurrencyFormat(String value) {
    if (value.startsWith('\$')) return value;
    final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
    final num = double.tryParse(cleaned);
    return num != null ? _formatCurrency(num) : value;
  }

  Widget _buildNotesSection(BuildContext context, List<String> notes) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200, width: 1),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Icon(Icons.info_outline, color: Colors.blue.shade700),
          title: Text(
            'Additional Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.blue.shade900,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: notes
              .map(
                (note) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          note,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.blue.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildInstructionsSection(
    BuildContext context,
    List<String> instructions,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.blue.shade700,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Instructions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.blue.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...instructions.map(
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        i,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningsSection(BuildContext context, List<String> warnings) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade300, width: 1.5),
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
                  'Important Warnings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...warnings.map(
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.circle, size: 6, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        w,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
