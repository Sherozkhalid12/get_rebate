import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/add_loan/controllers/add_loan_controller.dart';
import 'package:getrebate/app/widgets/custom_button.dart';
import 'package:getrebate/app/widgets/custom_text_field.dart';

class AddLoanView extends GetView<AddLoanController> {
  const AddLoanView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
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
        title: Text(
          'Add New Loan',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: AppTheme.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryBlue.withOpacity(0.1),
                      AppTheme.lightGreen.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.account_balance,
                            color: AppTheme.primaryBlue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create New Loan',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: AppTheme.black,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Fill in the details below to add a new loan',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppTheme.mediumGray),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Borrower Information Section
              _buildSectionHeader(context, 'Borrower Information'),
              const SizedBox(height: 16),

              CustomTextField(
                controller: controller.borrowerNameController,
                labelText: 'Borrower Name *',
                hintText: 'e.g., John Smith',
                maxLines: 1,
              ),

              const SizedBox(height: 16),

              CustomTextField(
                controller: controller.borrowerEmailController,
                labelText: 'Email (Optional)',
                hintText: 'e.g., john@example.com',
                keyboardType: TextInputType.emailAddress,
                maxLines: 1,
              ),

              const SizedBox(height: 16),

              CustomTextField(
                controller: controller.borrowerPhoneController,
                labelText: 'Phone (Optional)',
                hintText: 'e.g., (555) 123-4567',
                keyboardType: TextInputType.phone,
                maxLines: 1,
              ),

              const SizedBox(height: 24),

              // Loan Details Section
              _buildSectionHeader(context, 'Loan Details'),
              const SizedBox(height: 16),

              CustomTextField(
                controller: controller.loanAmountController,
                labelText: 'Loan Amount *',
                hintText: 'e.g., 500000',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.attach_money,
              ),

              const SizedBox(height: 16),

              CustomTextField(
                controller: controller.interestRateController,
                labelText: 'Interest Rate (%) *',
                hintText: 'e.g., 6.5',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),

              const SizedBox(height: 16),

              Obx(
                () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loan Term: ${controller.termInMonths} months (${(controller.termInMonths / 12).toStringAsFixed(0)} years)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: controller.termOptions.map((term) {
                        return ChoiceChip(
                          label: Text('${term / 12}y'),
                          selected: controller.termInMonths == term,
                          onSelected: (selected) {
                            if (selected) {
                              controller.updateTermInMonths(term);
                            }
                          },
                          selectedColor: AppTheme.lightGreen.withOpacity(0.3),
                          labelStyle: TextStyle(
                            color: controller.termInMonths == term
                                ? AppTheme.lightGreen
                                : AppTheme.darkGray,
                            fontWeight: controller.termInMonths == term
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Obx(
                () => DropdownButtonFormField<String>(
                  value: controller.loanType,
                  decoration: InputDecoration(
                    labelText: 'Loan Type',
                    labelStyle: const TextStyle(color: AppTheme.darkGray),
                    filled: true,
                    fillColor: AppTheme.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.lightGray),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.lightGray),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryBlue,
                        width: 2,
                      ),
                    ),
                  ),
                  items: controller.loanTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.updateLoanType(value);
                    }
                  },
                ),
              ),

              const SizedBox(height: 16),

              Obx(
                () => DropdownButtonFormField<String>(
                  value: controller.loanStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    labelStyle: const TextStyle(color: AppTheme.darkGray),
                    filled: true,
                    fillColor: AppTheme.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.lightGray),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.lightGray),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryBlue,
                        width: 2,
                      ),
                    ),
                  ),
                  items: controller.statusOptions.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.updateLoanStatus(value);
                    }
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Property Information Section
              _buildSectionHeader(context, 'Property Information (Optional)'),
              const SizedBox(height: 16),

              CustomTextField(
                controller: controller.propertyAddressController,
                labelText: 'Property Address',
                hintText: 'e.g., 123 Main St, New York, NY 10001',
                maxLines: 2,
              ),

              const SizedBox(height: 24),

              // Notes Section
              _buildSectionHeader(context, 'Notes (Optional)'),
              const SizedBox(height: 16),

              CustomTextField(
                controller: controller.notesController,
                labelText: 'Additional Notes',
                hintText: 'Any additional information...',
                maxLines: 4,
              ),

              const SizedBox(height: 32),

              // Submit Button
              Obx(
                () => CustomButton(
                  text: controller.isLoading ? 'Adding Loan...' : 'Add Loan',
                  onPressed: controller.isLoading
                      ? null
                      : controller.submitLoan,
                  icon: controller.isLoading ? null : Icons.add_circle_outline,
                  width: double.infinity,
                  height: 56,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: AppTheme.black,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
