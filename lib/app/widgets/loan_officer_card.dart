import 'package:flutter/material.dart';
import 'package:getrebate/app/theme/app_theme.dart';
import 'package:getrebate/app/models/loan_officer_model.dart';
import 'package:getrebate/app/widgets/custom_button.dart';
import 'package:getrebate/app/widgets/gradient_card.dart';

class LoanOfficerCard extends StatelessWidget {
  final LoanOfficerModel loanOfficer;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onContact;
  final VoidCallback? onToggleFavorite;

  const LoanOfficerCard({
    super.key,
    required this.loanOfficer,
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
                    colors: AppTheme.successGradient,
                  ),
                ),
                padding: const EdgeInsets.all(3),
                child: CircleAvatar(
                  radius: 27,
                  backgroundColor: Colors.white,
                  backgroundImage: (loanOfficer.profileImage != null && 
                                    loanOfficer.profileImage!.isNotEmpty &&
                                    (loanOfficer.profileImage!.startsWith('http://') || 
                                     loanOfficer.profileImage!.startsWith('https://')))
                      ? NetworkImage(loanOfficer.profileImage!)
                      : null,
                  child: (loanOfficer.profileImage == null || 
                         loanOfficer.profileImage!.isEmpty ||
                         (!loanOfficer.profileImage!.startsWith('http://') && 
                          !loanOfficer.profileImage!.startsWith('https://')))
                      ? const Icon(
                          Icons.account_balance,
                          color: AppTheme.lightGreen,
                          size: 30,
                        )
                      : null,
                ),
              ),

              const SizedBox(width: 12),

              // Loan Officer Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loanOfficer.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loanOfficer.company,
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
                          loanOfficer.rating.toString(),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.darkGray,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${loanOfficer.reviewCount} reviews)',
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
            children: loanOfficer.licensedStates.map((state) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppTheme.getLoanOfficerStateColors(state),
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

          if (loanOfficer.bio != null) ...[
            const SizedBox(height: 12),
            Text(
              loanOfficer.bio!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.darkGray,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'View Profile',
                  onPressed: onTap,
                  isOutlined: true,
                  backgroundColor: AppTheme.lightGreen,
                  textColor: AppTheme.lightGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'Chat',
                  onPressed: onContact,
                  backgroundColor: AppTheme.lightGreen,
                  textColor: AppTheme.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
