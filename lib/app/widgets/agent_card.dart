import 'package:flutter/material.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/models/agent_model.dart';
import 'package:getrebate/app/widgets/custom_button.dart';
import 'package:getrebate/app/widgets/gradient_card.dart';

class AgentCard extends StatelessWidget {
  final AgentModel agent;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onContact;
  final VoidCallback? onToggleFavorite;

  const AgentCard({
    super.key,
    required this.agent,
    this.isFavorite = false,
    this.onTap,
    this.onContact,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      gradientColors: AppTheme.cardGradient,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              // Profile Image
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppTheme.primaryGradient,
                  ),
                ),
                padding: const EdgeInsets.all(3),
                child: CircleAvatar(
                  radius: 27,
                  backgroundColor: Colors.white,
                  backgroundImage: agent.profileImage != null
                      ? NetworkImage(agent.profileImage!)
                      : null,
                  child: agent.profileImage == null
                      ? const Icon(
                          Icons.person,
                          color: AppTheme.primaryBlue,
                          size: 30,
                        )
                      : null,
                ),
              ),

              const SizedBox(width: 12),

              // Agent Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agent.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      agent.brokerage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mediumGray,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Rating
                        Icon(Icons.star, color: AppTheme.lightGreen, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          agent.rating.toString(),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.darkGray,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${agent.reviewCount} reviews)',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.mediumGray),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Favorite Button
              IconButton(
                onPressed: onToggleFavorite,
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : AppTheme.mediumGray,
                  size: 24,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Licensed States
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: agent.licensedStates.map((state) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppTheme.getAgentStateColors(state),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  state,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),

          if (agent.bio != null) ...[
            const SizedBox(height: 12),
            Text(
              agent.bio!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.darkGray,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 16),

          // Stats
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'View Profile',
                  onPressed: onTap,
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(text: 'Chat', onPressed: onContact),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.mediumGray, size: 16),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppTheme.darkGray,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumGray),
            ),
          ],
        ),
      ],
    );
  }
}
