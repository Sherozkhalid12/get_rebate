import 'package:flutter/material.dart';
import 'package:getrebate/app/theme/app_theme.dart';

class ProsConsChartWidget extends StatefulWidget {
  const ProsConsChartWidget({super.key});

  @override
  State<ProsConsChartWidget> createState() => _ProsConsChartWidgetState();
}

class _ProsConsChartWidgetState extends State<ProsConsChartWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(context),

          // Expandable content
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: _isExpanded
                ? _buildContent(context)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.compare_arrows, color: AppTheme.lightGreen, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Compare: Buyer Agent vs Listing Agent',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: AppTheme.mediumGray,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        const Divider(height: 1),

        // Tab bar
        Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppTheme.lightGray, width: 1),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.lightGreen,
            unselectedLabelColor: AppTheme.mediumGray,
            indicatorColor: AppTheme.lightGreen,
            indicatorWeight: 3,
            tabs: const [
              Tab(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'With Buyer Agent',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              Tab(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'With The Listing Agent',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Tab content
        SizedBox(
          height: 400,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildBuyerAgentContent(context),
              _buildListingAgentContent(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBuyerAgentContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'Pros', AppTheme.lightGreen),
          const SizedBox(height: 12),

          _buildProConItem(
            context,
            'Dedicated Advocacy',
            'Your agent works exclusively for your interests and negotiates on your behalf',
            Icons.verified_user,
            true,
          ),
          _buildProConItem(
            context,
            'Market Expertise',
            'Access to local market knowledge, comparable sales, and neighborhood insights',
            Icons.analytics,
            true,
          ),
          _buildProConItem(
            context,
            'Negotiation Power',
            'Can negotiate aggressively for better terms, price, and concessions',
            Icons.gavel,
            true,
          ),
          _buildProConItem(
            context,
            'Transaction Support',
            'Handles paperwork, inspections, appraisals, and closing coordination',
            Icons.description,
            true,
          ),
          _buildProConItem(
            context,
            'Network Access',
            'Connections to inspectors, contractors, lenders, and other professionals',
            Icons.network_check,
            true,
          ),

          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Cons', Colors.red[400]!),
          const SizedBox(height: 12),

          _buildProConItem(
            context,
            'Lower Rebate',
            'Rebates are based on the total commission. Since buyer\'s agents share the commission with the listing agent, your rebate may be smaller — but they may also help you negotiate a better price',
            Icons.trending_down,
            false,
          ),
          _buildProConItem(
            context,
            'Additional Contact',
            'Your agent has to rely on the timeliness of the listing agent for responses, etc.',
            Icons.people,
            false,
          ),
          _buildProConItem(
            context,
            'Potential Delays',
            'Communication through multiple parties may slow down negotiations',
            Icons.schedule,
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildListingAgentContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'Pros', AppTheme.lightGreen),
          const SizedBox(height: 12),

          _buildProConItem(
            context,
            'Higher Rebate',
            'Can receive 40% of the full commission received when it\'s 4.0% or more',
            Icons.trending_up,
            true,
          ),
          _buildProConItem(
            context,
            'Direct Communication',
            'Direct access to listing agent for immediate answers and faster decisions',
            Icons.chat,
            true,
          ),
          _buildProConItem(
            context,
            'Streamlined Process',
            'Fewer parties involved means faster negotiations and closing',
            Icons.speed,
            true,
          ),
          _buildProConItem(
            context,
            'Property Knowledge',
            'Listing agent knows the property intimately and can provide detailed insights',
            Icons.home,
            true,
          ),
          _buildProConItem(
            context,
            'Cost Efficiency',
            'No need to split commission with a Buyer\'s Agent, so potentially a higher rebate to you',
            Icons.savings,
            true,
          ),

          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Cons', Colors.red[400]!),
          const SizedBox(height: 12),

          _buildProConItem(
            context,
            'Limited Advocacy',
            'Agent cannot provide exclusive representation for your interests',
            Icons.warning,
            false,
          ),
          _buildProConItem(
            context,
            'Potential Conflicts',
            'Agent must remain neutral and cannot negotiate aggressively for you',
            Icons.balance,
            false,
          ),
          _buildProConItem(
            context,
            'Less Market Insight',
            'May not be able to share market value and other steps a dedicated Buyer Agent can offer',
            Icons.info_outline,
            false,
          ),
          _buildProConItem(
            context,
            'Self-Reliance',
            'You may need to handle more of the transaction details yourself',
            Icons.person,
            false,
          ),
          _buildProConItem(
            context,
            'Not Always Available',
            'Dual agency is not allowed in all states or by all agents',
            Icons.block,
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildProConItem(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    bool isPro,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPro
            ? AppTheme.lightGreen.withValues(alpha: 0.05)
            : Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPro
              ? AppTheme.lightGreen.withValues(alpha: 0.2)
              : Colors.red.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: isPro ? AppTheme.lightGreen : Colors.red[400],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.darkGray,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
