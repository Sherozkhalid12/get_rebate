import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/checklist/controllers/checklist_controller.dart';
import 'package:getrebate/app/routes/app_pages.dart';
import 'package:getrebate/app/modules/buyer/controllers/buyer_controller.dart';
import 'package:getrebate/app/controllers/main_navigation_controller.dart';

class ChecklistView extends GetView<ChecklistController> {
  const ChecklistView({super.key});

  @override
  Widget build(BuildContext context) {
    // Get checklist type from arguments
    final args = Get.arguments as Map<String, dynamic>?;
    final type = args?['type'] as String? ?? 'buyer';
    final title = args?['title'] as String? ?? 'Checklist';
    
    final isBuyer = type == 'buyer';
    final items = isBuyer 
        ? controller.getBuyerChecklist() 
        : controller.getSellerChecklist();

    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        backgroundColor: isBuyer ? AppTheme.primaryBlue : AppTheme.lightGreen,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isBuyer 
                  ? AppTheme.primaryGradient 
                  : AppTheme.successGradient,
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppTheme.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _buildChecklist(context, title, items, isBuyer),
        ),
      ),
    );
  }

  Widget _buildChecklist(
    BuildContext context,
    String title,
    List<String> items,
    bool isBuyer,
  ) {
    final color = isBuyer ? AppTheme.primaryBlue : AppTheme.lightGreen;
    final icon = isBuyer ? Icons.shopping_bag : Icons.sell;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isBuyer
                          ? 'Follow these steps to buy a home and receive your rebate!'
                          : 'Follow these steps to sell your home and save on fees!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.darkGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...List.generate(items.length, (index) {
          final stepNumber = index + 1;
          final hasLink = isBuyer 
              ? controller.hasLinkForBuyerItem(index)
              : controller.hasLinkForSellerItem(index);
          final linkAction = isBuyer 
              ? controller.getLinkActionForBuyerItem(index)
              : controller.getLinkActionForSellerItem(index);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        border: Border.all(color: color, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '$stepNumber',
                          style: TextStyle(
                            color: color,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        items[index],
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.darkGray,
                          height: 1.5,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                if (hasLink && linkAction != null) ...[
                  const SizedBox(height: 12),
                  _buildActionButton(context, linkAction, color),
                ],
              ],
            ),
          );
        }),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.lightGray,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Note',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isBuyer
                    ? 'The rebate will typically be a credit to you at closing and will be clearly displayed on the Settlement Statement at closing. It is possible that a rebate will not be allowed depending on loan programs, choice of builder, etc. but it is rare if you and your agent follow the necessary steps. All Agents on this site have access to a more detailed checklist so rebate compliance is met.'
                    : 'Most agents and sellers will elect to go with the instant lower listing fee calculating in the rebate. See the rebate calculator. If you elect to go with the rebate at closing on the Settlement Statement, all Agents on this site have access to a more detailed checklist so rebate compliance is met.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.darkGray,
                  height: 1.5,
                  fontSize: 13,
                ),
              ),
              if (!isBuyer) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToRebateCalculator(),
                    icon: Icon(Icons.calculate, color: color, size: 20),
                    label: Text(
                      'See Rebate Calculator',
                      style: TextStyle(color: color, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: color, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => _printChecklist(context, title, items, color),
              icon: const Icon(Icons.print),
              label: const Text('Print Checklist'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, String action, Color color) {
    String buttonText;
    IconData icon;
    VoidCallback onPressed;

    switch (action) {
      case 'search_loan_officer':
        buttonText = 'Search for Loan Officers';
        icon = Icons.account_balance;
        onPressed = () => _navigateToLoanOfficers();
        break;
      case 'search_agents':
        buttonText = 'Search for Agents';
        icon = Icons.person_search;
        onPressed = () => _navigateToAgents();
        break;
      case 'search_homes':
        buttonText = 'Search for Homes';
        icon = Icons.home;
        onPressed = () => _navigateToHomes();
        break;
      case 'calculate_rebate':
        buttonText = 'Calculate Rebate';
        icon = Icons.calculate;
        onPressed = () => _navigateToRebateCalculator();
        break;
      case 'leave_review':
        buttonText = 'Leave Review';
        icon = Icons.rate_review;
        onPressed = () => _navigateToReview();
        break;
      default:
        buttonText = 'Action';
        icon = Icons.arrow_forward;
        onPressed = () {};
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 20),
        label: Text(
          buttonText,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  void _navigateToLoanOfficers() {
    // Navigate to main page and switch to loan officers tab
    Get.offAllNamed(AppPages.MAIN);
    // Wait a bit for the page to load, then switch tab
    Future.delayed(const Duration(milliseconds: 300), () {
      try {
        final mainNavController = Get.find<MainNavigationController>();
        mainNavController.changeIndex(0); // Switch to home tab (BuyerView)
        
        // Then switch to loan officers tab within BuyerView
        Future.delayed(const Duration(milliseconds: 200), () {
          try {
            final buyerController = Get.find<BuyerController>();
            buyerController.setSelectedTab(3); // Loan Officers tab
          } catch (e) {
            // If controller not found, navigate directly
            Get.toNamed(AppPages.MAIN);
          }
        });
      } catch (e) {
        Get.toNamed(AppPages.MAIN);
      }
    });
  }

  void _navigateToAgents() {
    // Navigate to main page and switch to agents tab
    Get.offAllNamed(AppPages.MAIN);
    Future.delayed(const Duration(milliseconds: 300), () {
      try {
        final mainNavController = Get.find<MainNavigationController>();
        mainNavController.changeIndex(0); // Switch to home tab (BuyerView)
        
        Future.delayed(const Duration(milliseconds: 200), () {
          try {
            final buyerController = Get.find<BuyerController>();
            buyerController.setSelectedTab(0); // Agents tab
          } catch (e) {
            Get.toNamed(AppPages.MAIN);
          }
        });
      } catch (e) {
        Get.toNamed(AppPages.MAIN);
      }
    });
  }

  void _navigateToHomes() {
    // Navigate to main page and switch to homes tab
    Get.offAllNamed(AppPages.MAIN);
    Future.delayed(const Duration(milliseconds: 300), () {
      try {
        final mainNavController = Get.find<MainNavigationController>();
        mainNavController.changeIndex(0); // Switch to home tab (BuyerView)
        
        Future.delayed(const Duration(milliseconds: 200), () {
          try {
            final buyerController = Get.find<BuyerController>();
            buyerController.setSelectedTab(1); // Homes for Sale tab
          } catch (e) {
            Get.toNamed(AppPages.MAIN);
          }
        });
      } catch (e) {
        Get.toNamed(AppPages.MAIN);
      }
    });
  }

  void _navigateToRebateCalculator() {
    Get.toNamed(AppPages.REBATE_CALCULATOR);
  }

  void _navigateToReview() {
    // Navigate to post-closing survey/review
    // Determine if buyer or seller from current route arguments
    final args = Get.arguments as Map<String, dynamic>?;
    final type = args?['type'] as String? ?? 'buyer';
    final isBuyer = type == 'buyer';
    
    Get.toNamed(
      AppPages.POST_CLOSING_SURVEY,
      arguments: {
        'agentId': 'checklist-agent',
        'agentName': 'Your Agent',
        'userId': 'checklist-user',
        'transactionId': 'checklist-transaction',
        'isBuyer': isBuyer,
      },
    );
  }

  void _printChecklist(
    BuildContext context,
    String title,
    List<String> items,
    Color color,
  ) {
    Get.dialog(
      Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      ...List.generate(items.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(
                                  border: Border.all(color: color, width: 2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  items[index],
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppTheme.darkGray,
                                        height: 1.4,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Get.snackbar(
                        'Print',
                        'Print functionality will be available soon!',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: color,
                        colorText: Colors.white,
                      );
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('Print'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

