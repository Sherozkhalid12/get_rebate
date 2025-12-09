import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/favorites/controllers/favorites_controller.dart';
import 'package:getrebate/app/widgets/agent_card.dart';
import 'package:getrebate/app/widgets/loan_officer_card.dart';

class FavoritesView extends GetView<FavoritesController> {
  const FavoritesView({super.key});

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
          'Favorites',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tabs
            _buildTabs(context),

            // Content
            Expanded(child: _buildContent(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back, color: AppTheme.darkGray),
          ),
          Expanded(
            child: Text(
              'My Favorites',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear_all') {
                controller.clearAllFavorites();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear All Favorites'),
                  ],
                ),
              ),
            ],
            child: const Icon(Icons.more_vert, color: AppTheme.darkGray),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    return Container(
      color: AppTheme.white,
      child: Obx(
        () => Row(
          children: [
            Expanded(
              child: _buildTab(
                context,
                'Agents (${controller.favoriteAgents.length})',
                0,
                Icons.person,
              ),
            ),
            Expanded(
              child: _buildTab(
                context,
                'Loan Officers (${controller.favoriteLoanOfficers.length})',
                1,
                Icons.account_balance,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    String title,
    int index,
    IconData icon,
  ) {
    final isSelected = controller.selectedTab == index;

    return GestureDetector(
      onTap: () => controller.setSelectedTab(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withOpacity(0.1)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryBlue : AppTheme.mediumGray,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isSelected
                      ? AppTheme.primaryBlue
                      : AppTheme.mediumGray,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Obx(() {
      if (controller.selectedTab == 0) {
        return _buildAgentsList(context);
      } else {
        return _buildLoanOfficersList(context);
      }
    });
  }

  Widget _buildAgentsList(BuildContext context) {
    return Obx(() {
      if (controller.favoriteAgents.isEmpty) {
        return _buildEmptyState(
          context,
          'No favorite agents',
          'Agents you favorite will appear here',
          Icons.person_search,
          'Find Agents',
          () => Get.toNamed('/buyer'),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: controller.favoriteAgents.length,
        itemBuilder: (context, index) {
          final agent = controller.favoriteAgents[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child:
                AgentCard(
                      agent: agent,
                      isFavorite: true,
                      onTap: () => controller.viewAgentProfile(agent),
                      onContact: () => controller.contactAgent(agent),
                      onToggleFavorite: () =>
                          controller.removeFavoriteAgent(agent.id),
                    )
                    .animate()
                    .slideX(
                      begin: 0.3,
                      duration: 600.ms,
                      curve: Curves.easeOut,
                      delay: (index * 100).ms,
                    )
                    .fadeIn(duration: 600.ms, delay: (index * 100).ms),
          );
        },
      );
    });
  }

  Widget _buildLoanOfficersList(BuildContext context) {
    return Obx(() {
      if (controller.favoriteLoanOfficers.isEmpty) {
        return _buildEmptyState(
          context,
          'No favorite loan officers',
          'Loan officers you favorite will appear here',
          Icons.account_balance,
          'Find Loan Officers',
          () => Get.toNamed('/buyer'),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: controller.favoriteLoanOfficers.length,
        itemBuilder: (context, index) {
          final loanOfficer = controller.favoriteLoanOfficers[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child:
                LoanOfficerCard(
                      loanOfficer: loanOfficer,
                      isFavorite: true,
                      onTap: () =>
                          controller.viewLoanOfficerProfile(loanOfficer),
                      onContact: () =>
                          controller.contactLoanOfficer(loanOfficer),
                      onToggleFavorite: () =>
                          controller.removeFavoriteLoanOfficer(loanOfficer.id),
                    )
                    .animate()
                    .slideX(
                      begin: 0.3,
                      duration: 600.ms,
                      curve: Curves.easeOut,
                      delay: (index * 100).ms,
                    )
                    .fadeIn(duration: 600.ms, delay: (index * 100).ms),
          );
        },
      );
    });
  }

  Widget _buildEmptyState(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    String buttonText,
    VoidCallback onButtonPressed,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(icon, size: 40, color: AppTheme.primaryBlue),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.darkGray,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.mediumGray,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onButtonPressed,
              icon: const Icon(Icons.search),
              label: Text(buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
