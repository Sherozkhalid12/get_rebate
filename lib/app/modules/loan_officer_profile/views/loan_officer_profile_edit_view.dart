import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/models/mortgage_types.dart';

class LoanOfficerProfileEditView extends StatefulWidget {
  const LoanOfficerProfileEditView({super.key});

  @override
  State<LoanOfficerProfileEditView> createState() =>
      _LoanOfficerProfileEditViewState();
}

class _LoanOfficerProfileEditViewState
    extends State<LoanOfficerProfileEditView> {
  // Track selected specialty products
  final Set<String> _selectedProducts = <String>{};

  @override
  void initState() {
    super.initState();
    // Load existing selections (would come from controller in real app)
    _selectedProducts.addAll([
      MortgageTypes.fhaLoans,
      MortgageTypes.vaLoans,
      MortgageTypes.conventionalConforming,
    ]);
  }

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
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveAndExit,
            child: const Text('Save', style: TextStyle(color: AppTheme.white)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                color: AppTheme.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance,
                          color: AppTheme.lightGreen,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Specialty Products',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: AppTheme.black,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Select the mortgage loan types you specialize in. Buyers will see your areas of expertise on your profile.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.darkGray,
                      ),
                    ),
                  ],
                ),
              ),

              // Mortgage Types List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: MortgageTypes.getAll().length,
                itemBuilder: (context, index) {
                  final mortgageType = MortgageTypes.getAll()[index];
                  final description = MortgageTypes.getDescription(
                    mortgageType,
                  );
                  final isSelected = _selectedProducts.contains(mortgageType);

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedProducts.remove(mortgageType);
                          } else {
                            _selectedProducts.add(mortgageType);
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isSelected,
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedProducts.add(mortgageType);
                                  } else {
                                    _selectedProducts.remove(mortgageType);
                                  }
                                });
                              },
                              activeColor: AppTheme.lightGreen,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mortgageType,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: AppTheme.black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  if (description != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      description,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppTheme.darkGray,
                                            height: 1.4,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Selection Summary
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.lightGreen.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.lightGreen,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_selectedProducts.length} specialty product${_selectedProducts.length != 1 ? 's' : ''} selected',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.darkGray,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 100), // Bottom padding for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveAndExit,
        backgroundColor: AppTheme.lightGreen,
        icon: const Icon(Icons.check, color: Colors.white),
        label: const Text(
          'Save Changes',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _saveAndExit() {
    // TODO: Save to backend via controller
    Get.snackbar(
      'Success',
      'Specialty products updated successfully!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.lightGreen,
      colorText: AppTheme.white,
    );
    Navigator.pop(context);
  }
}
