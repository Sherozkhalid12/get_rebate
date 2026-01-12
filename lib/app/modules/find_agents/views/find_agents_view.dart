import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/modules/find_agents/controllers/find_agents_controller.dart';
import 'package:getrebate/app/models/agent_model.dart';
import 'package:getrebate/app/widgets/custom_text_field.dart';
import 'package:getrebate/app/widgets/custom_button.dart';
import 'package:getrebate/app/utils/api_constants.dart';

class FindAgentsView extends GetView<FindAgentsController> {
  const FindAgentsView({super.key});

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
          'Find Agents Near You',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => controller.refreshAgents(),
          color: AppTheme.primaryBlue,
          child: Column(
            children: [
              // Search Section
              _buildSearchSection(context),

              // Agents List
              Expanded(child: _buildAgentsList(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppTheme.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            final zipCode = controller.selectedZipCode.value;
            final hasZipCode = zipCode.isNotEmpty;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasZipCode
                      ? 'Agents in ${zipCode}'
                      : 'All Agents',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hasZipCode) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Local agents shown first, then nearby agents',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.mediumGray,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            );
          }),
          const SizedBox(height: 12),
          CustomTextField(
            controller: controller.searchController,
            labelText: 'Search by name, ZIP code, or other details',
            prefixIcon: Icons.search,
            onChanged: controller.searchAgents,
            keyboardType: TextInputType.text,
          ),
        ],
      ),
    );
  }

  Widget _buildAgentsList(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(
          child: SpinKitFadingCircle(
            color: AppTheme.primaryBlue,
            size: 40,
          ),
        );
      }

      if (controller.agents.isEmpty) {
        return _buildEmptyState(context);
      }

      // Access reactive RxInt values DIRECTLY inside Obx - this is critical for GetX to track them
      // Force GetX to track by accessing .value property
      final currentPage = controller.currentPage.value;
      final totalPages = controller.totalPages.value;
      final canLoadMore = currentPage < totalPages;
      
      if (kDebugMode) {
        print('📋 Building agents list:');
        print('   Agents count: ${controller.agents.length}');
        print('   Current page: $currentPage');
        print('   Total pages: $totalPages');
        print('   Can load more: $canLoadMore');
        print('   ItemCount will be: ${controller.agents.length + (canLoadMore ? 1 : 0)}');
      }
      
      // Show button if we have agents AND (can load more OR totalPages > 1)
      // This ensures button shows even if there's a timing issue
      final shouldShowButton = controller.agents.isNotEmpty && (canLoadMore || totalPages > 1);
      
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: controller.agents.length + (shouldShowButton ? 1 : 0),
        itemBuilder: (context, index) {
          // Show Load More button at the end
          if (index == controller.agents.length && shouldShowButton) {
            if (kDebugMode) {
              print('✅ Rendering Load More button at index $index');
            }
            return _buildLoadMoreButton(context);
          }
          
          final agent = controller.agents[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildAgentCard(context, agent),
          );
        },
      );
    });
  }
  
  Widget _buildLoadMoreButton(BuildContext context) {
    return Obx(() {
      // Access reactive values to track loading state
      final isLoadingMore = controller.isLoadingMore;
      final currentPage = controller.currentPage.value;
      final totalPages = controller.totalPages.value;
      
      if (kDebugMode) {
        print('🔘 Building Load More button:');
        print('   Current page: $currentPage');
        print('   Total pages: $totalPages');
        print('   Is loading: $isLoadingMore');
      }
      
      return Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryBlue.withOpacity(0.05),
                AppTheme.primaryBlue.withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            children: [
              // Count text with icon
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 18,
                    color: AppTheme.mediumGray,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Showing ${controller.agents.length} of ${controller.totalAgents} agents',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.mediumGray,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Load More Button
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: isLoadingMore
                    ? Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Loading more agents...',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : CustomButton(
                        text: 'Load More Agents',
                        onPressed: () => controller.loadMoreAgents(),
                        icon: Icons.expand_more,
                        height: 48,
                        isOutlined: false,
                      ),
              ),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(
            duration: 500.ms,
            curve: Curves.easeOut,
          )
          .slideY(
            begin: 0.3,
            duration: 500.ms,
            curve: Curves.easeOut,
          )
          .scale(
            duration: 500.ms,
            curve: Curves.easeOut,
          );
    });
  }

  Widget _buildAgentCard(BuildContext context, AgentModel agent) {
    // Use helper function to normalize URL (AgentModel already normalizes, but ensure consistency)
    final profileImageUrl = ApiConstants.getImageUrl(agent.profileImage);
    if (kDebugMode && profileImageUrl != null) {
      print('🖼️ FindAgentsView: Agent profile image URL: $profileImageUrl');
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Agent Header
            Row(
              children: [
                // Profile Image
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                  backgroundImage: (profileImageUrl != null && 
                                   profileImageUrl.isNotEmpty &&
                                   (profileImageUrl.startsWith('http://') || 
                                    profileImageUrl.startsWith('https://')))
                      ? NetworkImage(profileImageUrl)
                      : null,
                  child: (profileImageUrl == null || 
                         profileImageUrl.isEmpty ||
                         (!profileImageUrl.startsWith('http://') && 
                          !profileImageUrl.startsWith('https://')))
                      ? const Icon(
                          Icons.person,
                          color: AppTheme.primaryBlue,
                          size: 30,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Agent Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              agent.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppTheme.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          if (agent.isVerified)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.verified,
                                color: AppTheme.primaryBlue,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (agent.brokerage.isNotEmpty)
                        Text(
                          agent.brokerage,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.mediumGray,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${agent.rating.toStringAsFixed(1)} (${agent.reviewCount} ${agent.reviewCount == 1 ? 'review' : 'reviews'})',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppTheme.darkGray,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Bio
            if (agent.bio != null && agent.bio!.isNotEmpty) ...[
              Text(
                agent.bio!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkGray,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
            ],

            // Licensed States
            if (agent.licensedStates.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: agent.licensedStates.take(3).map((state) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      state,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  'Searches',
                  agent.searchesAppearedIn.toString(),
                ),
                _buildStatItem(
                  context,
                  'Views',
                  agent.profileViews.toString(),
                ),
                _buildStatItem(
                  context,
                  'Contacts',
                  agent.contacts.toString(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Chat',
                    onPressed: () => controller.contactAgent(agent),
                    icon: Icons.chat,
                    height: 48,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'View Profile',
                    onPressed: () => controller.viewAgentProfile(agent),
                    icon: Icons.person,
                    isOutlined: true,
                    height: 48,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.mediumGray,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
              child: const Icon(
                Icons.person_search,
                size: 40,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No agents found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.darkGray,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Obx(() => Text(
              controller.searchQuery.value.isNotEmpty
                  ? 'No agents found matching "${controller.searchQuery.value}". Try a different search term.'
                  : 'No agents are currently available. Please try again later.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.mediumGray,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            )),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Search Different Area',
              onPressed: () => Navigator.pop(context),
              icon: Icons.search,
              height: 48,
            ),
          ],
        ),
      ),
    );
  }
}
