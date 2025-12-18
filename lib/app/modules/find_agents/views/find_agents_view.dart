import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
          Text(
            'Agents in ${controller.selectedZipCode.value}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: controller.searchController,
            labelText: 'Search agents by name, brokerage, or other details',
            prefixIcon: Icons.search,
            onChanged: controller.searchAgents,
          ),
        ],
      ),
    );
  }

  Widget _buildAgentsList(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
          ),
        );
      }

      if (controller.agents.isEmpty) {
        return _buildEmptyState(context);
      }

      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: controller.agents.length,
        itemBuilder: (context, index) {
          final agent = controller.agents[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildAgentCard(context, agent),
          );
        },
      );
    });
  }

  Widget _buildAgentCard(BuildContext context, AgentModel agent) {
    // Build full profile image URL if needed
    String? profileImageUrl = agent.profileImage;
    if (profileImageUrl != null && 
        profileImageUrl.isNotEmpty && 
        !profileImageUrl.startsWith('http://') && 
        !profileImageUrl.startsWith('https://')) {
      final baseUrl = ApiConstants.baseUrl.endsWith('/') 
          ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 1)
          : ApiConstants.baseUrl;
      profileImageUrl = profileImageUrl.replaceAll('\\', '/');
      final cleanUrl = profileImageUrl.startsWith('/') 
          ? profileImageUrl.substring(1) 
          : profileImageUrl;
      profileImageUrl = '$baseUrl/$cleanUrl';
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
              controller.selectedZipCode.value.isNotEmpty
                  ? 'No agents are currently available in ZIP code ${controller.selectedZipCode.value}. Try searching in a different ZIP code.'
                  : 'No agents are currently available in this area. Try searching in a different ZIP code.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.mediumGray,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            )),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Search Different Area',
              onPressed: () => Get.back(),
              icon: Icons.search,
              height: 48,
            ),
          ],
        ),
      ),
    );
  }
}
