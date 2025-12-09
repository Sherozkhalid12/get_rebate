import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/widgets/custom_button.dart';
import 'package:getrebate/app/widgets/custom_text_field.dart';

class RebateCalculator extends StatefulWidget {
  const RebateCalculator({super.key});

  @override
  State<RebateCalculator> createState() => _RebateCalculatorState();
}

class _RebateCalculatorState extends State<RebateCalculator> {
  final _priceController = TextEditingController();
  final _commissionController = TextEditingController();

  double _rebateAmount = 0.0;
  double _finalCommission = 0.0;
  bool _isCalculated = false;

  @override
  void initState() {
    super.initState();
    _commissionController.text = '3.0'; // Default commission rate
  }

  void _calculateRebate() {
    final price =
        double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0.0;
    final commissionRate = double.tryParse(_commissionController.text) ?? 0.0;

    if (price <= 0) {
      Get.snackbar('Error', 'Please enter a valid property price');
      return;
    }

    if (commissionRate <= 0 || commissionRate > 10) {
      Get.snackbar('Error', 'Please enter a valid commission rate (0-10%)');
      return;
    }

    setState(() {
      // Calculate total commission (typically 6% total, split between buyer and seller agents)
      final totalCommission = price * (commissionRate / 100);

      // Calculate rebate (typically 1-2% of purchase price)
      _rebateAmount = price * 0.015; // 1.5% rebate

      // Calculate final commission after rebate
      _finalCommission = totalCommission - _rebateAmount;

      _isCalculated = true;
    });
  }

  void _resetCalculator() {
    setState(() {
      _priceController.clear();
      _commissionController.text = '3.0';
      _rebateAmount = 0.0;
      _finalCommission = 0.0;
      _isCalculated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        title: const Text(
          'Rebate Calculator',
          style: TextStyle(color: AppTheme.white),
        ),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: AppTheme.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppTheme.primaryGradient,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context),

            const SizedBox(height: 24),

            // Calculator Form
            _buildCalculatorForm(context),

            const SizedBox(height: 24),

            // Results
            if (_isCalculated) _buildResults(context),

            const SizedBox(height: 24),

            // Action Buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(
                    Icons.calculate,
                    color: AppTheme.primaryBlue,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calculate Your Rebate',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'See how much you can save on your real estate transaction',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorForm(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Property Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // Property Price
            CustomTextField(
              controller: _priceController,
              labelText: 'Property Price',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.attach_money,
              hintText: 'Enter property price (e.g., 500000)',
              onChanged: (value) {
                // Format number with commas
                if (value.isNotEmpty) {
                  final number = double.tryParse(value.replaceAll(',', ''));
                  if (number != null) {
                    _priceController.value = TextEditingValue(
                      text: number.toString().replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]},',
                      ),
                      selection: TextSelection.collapsed(
                        offset: _priceController.text.length,
                      ),
                    );
                  }
                }
              },
            ),

            const SizedBox(height: 16),

            // Commission Rate
            CustomTextField(
              controller: _commissionController,
              labelText: 'Commission Rate (%)',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.percent,
              hintText: 'Enter commission rate (e.g., 3.0)',
            ),

            const SizedBox(height: 20),

            // Calculate Button
            CustomButton(
              text: 'Calculate Rebate',
              onPressed: _calculateRebate,
              width: double.infinity,
              icon: Icons.calculate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Rebate Calculation',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // Rebate Amount
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.lightGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.lightGreen, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Rebate',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.lightGreen,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        'Amount you\'ll receive back',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '\$${_rebateAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.lightGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Final Commission
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryBlue, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Agent Commission',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        'After rebate deduction',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '\$${_finalCommission.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Savings Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.lightGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This is an estimate. Actual rebate amounts may vary based on the specific agent and transaction details.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.mediumGray,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: 'Reset',
            onPressed: _resetCalculator,
            isOutlined: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CustomButton(
            text: 'Contact Agent',
            onPressed: () {
              Get.snackbar('Info', 'Contact agent feature coming soon!');
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    _commissionController.dispose();
    super.dispose();
  }
}
