import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/models/listing.dart';
import 'package:getrebate/app/services/nearby_agents_service.dart';
import 'package:getrebate/app/theme/app_theme.dart';

class NearbyAgentsWidget extends StatefulWidget {
  final Listing listing;

  const NearbyAgentsWidget({super.key, required this.listing});

  @override
  State<NearbyAgentsWidget> createState() => _NearbyAgentsWidgetState();
}

class _NearbyAgentsWidgetState extends State<NearbyAgentsWidget> {
  List<AgentWithRebate> _agents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNearbyAgents();
  }

  Future<void> _loadNearbyAgents() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final agents = await NearbyAgentsService.findNearbyAgentsWithRebates(
        listing: widget.listing,
        maxResults: 5,
      );

      setState(() {
        _agents = agents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar('Error', 'Failed to load nearby agents: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people_outline, color: AppTheme.lightGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Nearby Agents Offering Rebates',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_agents.isEmpty)
            _buildEmptyState(context)
          else
            _buildAgentsList(context),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 48, color: AppTheme.mediumGray),
            const SizedBox(height: 12),
            Text(
              'No agents found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.darkGray,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'No agents offering rebates were found in this area.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.mediumGray),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentsList(BuildContext context) {
    return Column(
      children: _agents.map((agentWithRebate) {
        return _buildAgentCard(context, agentWithRebate);
      }).toList(),
    );
  }

  Widget _buildAgentCard(
    BuildContext context,
    AgentWithRebate agentWithRebate,
  ) {
    final agent = agentWithRebate.agent;

    return InkWell(
      onTap: () => _viewAgentProfile(agent),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.lightGray.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.lightGreen.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            // Agent avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.lightGreen.withOpacity(0.1),
              backgroundImage: agent.profileImage != null
                  ? NetworkImage(agent.profileImage!)
                  : null,
              child: agent.profileImage == null
                  ? Text(
                      agent.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: AppTheme.lightGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),

            const SizedBox(width: 12),

            // Agent info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          agent.name,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.black,
                                fontWeight: FontWeight.w600,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: AppTheme.mediumGray,
                      ),
                    ],
                  ),
                  Text(
                    agent.brokerage,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${agent.rating.toStringAsFixed(1)} (${agent.reviewCount})',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.mediumGray),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          agentWithRebate.formattedDistance,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.mediumGray),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Rebate info
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  agentWithRebate.formattedPotentialRebate,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.lightGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Potential Rebate',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap for profile',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryBlue,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),

            const SizedBox(width: 8),

            // Contact button
            IconButton(
              onPressed: () => _contactAgent(agent),
              icon: Icon(
                Icons.message_outlined,
                color: AppTheme.lightGreen,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewAgentProfile(agent) {
    // Navigate to agent profile page with full details
    Get.toNamed('/agent-profile', arguments: {'agent': agent});
  }

  void _contactAgent(agent) {
    final propertyAddress = widget.listing.address.toString();
    final propertyPrice =
        '\$${(widget.listing.priceCents / 100).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.home_outlined, color: AppTheme.primaryBlue, size: 24),
            const SizedBox(width: 8),
            Expanded(child: Text('Contact ${agent.name}')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property Information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.lightGreen.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Property of Interest:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppTheme.mediumGray,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            propertyAddress,
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.attach_money,
                          size: 16,
                          color: AppTheme.mediumGray,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          propertyPrice,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.lightGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Divider(),
              const SizedBox(height: 8),

              // Agent Contact Information
              Text(
                'Agent Contact:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.black,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: AppTheme.primaryBlue),
                  const SizedBox(width: 8),
                  Expanded(child: Text(agent.phone ?? 'Not provided')),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.email, size: 16, color: AppTheme.primaryBlue),
                  const SizedBox(width: 8),
                  Expanded(child: Text(agent.email)),
                ],
              ),
              if (agent.bio != null) ...[
                const SizedBox(height: 12),
                Text(
                  'About ${agent.name}:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  agent.bio!,
                  style: TextStyle(fontSize: 12, color: AppTheme.darkGray),
                ),
              ],

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This agent will be notified of your interest in this property',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryBlue,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
          ElevatedButton.icon(
            onPressed: () {
              Get.back();
              // TODO: Send inquiry to agent with property details
              _sendInquiryToAgent(agent, widget.listing);
            },
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Send Inquiry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightGreen,
              foregroundColor: AppTheme.white,
            ),
          ),
        ],
      ),
    );
  }

  void _sendInquiryToAgent(agent, listing) {
    // TODO: Implement API call to send inquiry with property details
    Get.snackbar(
      'Inquiry Sent!',
      '${agent.name} will be notified of your interest in ${listing.address.street}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.lightGreen,
      colorText: AppTheme.white,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.check_circle, color: AppTheme.white),
    );
  }
}
