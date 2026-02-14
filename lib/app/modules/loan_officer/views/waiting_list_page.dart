import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getrebate/app/models/loan_officer_zip_code_model.dart';
import 'package:getrebate/app/modules/loan_officer/controllers/loan_officer_controller.dart';
import 'package:getrebate/app/theme/app_theme.dart';

class WaitingListPage extends StatefulWidget {
  final LoanOfficerZipCodeModel zipCode;

  const WaitingListPage({
    super.key,
    required this.zipCode,
  });

  @override
  State<WaitingListPage> createState() => _WaitingListPageState();
}

class _WaitingListPageState extends State<WaitingListPage> {
  late final LoanOfficerController _controller;
  late final String _zipCode;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<LoanOfficerController>();
    _zipCode = widget.zipCode.postalCode;
    Future.microtask(() => _controller.fetchWaitingListEntries(_zipCode));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        title: const Text('Waiting list'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.white,
        leading: const BackButton(color: AppTheme.black),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppTheme.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.zipCode.city != null && widget.zipCode.city!.isNotEmpty
                      ? '${widget.zipCode.postalCode} (${widget.zipCode.city})'
                      : widget.zipCode.postalCode,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Claimed by another loan officer. Here are the loan officers waiting for it.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.white.withOpacity(0.85),
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Obx(() {
                final isLoading = _controller.isWaitingListLoading(_zipCode);
                final raw = _controller.waitingListEntries(_zipCode);
                final entries = raw
                    .where((e) =>
                        e.role == null ||
                        e.role!.toLowerCase() == 'loanofficer')
                    .toList();

                if (isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 3),
                  );
                }

                if (entries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: AppTheme.lightGray,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No loan officers are waiting yet.',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppTheme.darkGray,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We will notify you once the ZIP code is free.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.mediumGray,
                                ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final entry = entries[index];
                    final initial = entry.name.isNotEmpty
                        ? entry.name[0].toUpperCase()
                        : '?';
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppTheme.lightGray.withOpacity(0.4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.black.withOpacity(0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: AppTheme.primaryBlue.withOpacity(0.12),
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.name.isNotEmpty ? entry.name : 'Loan Officer',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: AppTheme.black,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  entry.email,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: AppTheme.mediumGray),
                                ),
                                const SizedBox(height: 6),
                                if (entry.formattedTimestamp.isNotEmpty)
                                  Text(
                                    'Joined ${entry.formattedTimestamp}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppTheme.darkGray,
                                        ),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppTheme.mediumGray,
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
