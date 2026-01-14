import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/listing.dart';
import '../utils/rebate.dart';

class ListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback? onTap;

  const ListingCard({super.key, required this.listing, this.onTap});

  String _formatMoney(int cents) {
    final int dollars = cents ~/ 100;
    final int remainder = cents % 100;
    final String remStr = remainder.toString().padLeft(2, '0');
    final String withCommas = dollars.toString().replaceAll(
      RegExp(r"\B(?=(\d{3})+(?!\d))"),
      ',',
    );
    return '$withCommas.$remStr';
  }

  @override
  Widget build(BuildContext context) {
    final RebateEstimate rebate = estimateRebate(
      priceCents: listing.priceCents,
      bacPercent: listing.bacPercent,
      dualAgencyAllowed: listing.dualAgencyAllowed,
    );

    final String priceText = _formatMoney(listing.priceCents);
    final String ownAgentRebateText = _formatMoney(rebate.ownAgentRebateCents);
    final String directRebateText = rebate.directRebateMaxCents != null
        ? '${_formatMoney(rebate.directRebateCents)} - ${_formatMoney(rebate.directRebateMaxCents!)}'
        : _formatMoney(rebate.directRebateCents);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _ListingPhotoHero(
              photoUrl: listing.photoUrls.isNotEmpty
                  ? listing.photoUrls.first
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    priceText,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listing.address.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      _InfoChip(
                        label: 'Dual Agency',
                        value: listing.dualAgencyAllowed ? 'Allowed' : 'No',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _RebateTile(
                          title: 'Rebate w/ Own Agent',
                          amount: ownAgentRebateText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _RebateTile(
                          title: 'With Listing Agent',
                          amount: directRebateText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingPhotoHero extends StatelessWidget {
  final String? photoUrl;
  const _ListingPhotoHero({required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final Widget image = (photoUrl == null || photoUrl!.isEmpty)
        ? Container(
            height: 160,
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: const Icon(Icons.home, size: 48, color: Colors.grey),
          )
        : CachedNetworkImage(
            imageUrl: photoUrl!,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
            cacheKey: photoUrl,
            memCacheWidth: 400,
            memCacheHeight: 300,
            maxWidthDiskCache: 800,
            maxHeightDiskCache: 600,
            fadeInDuration: Duration.zero,
            placeholder: (context, url) => Container(
              height: 160,
              width: double.infinity,
              color: Colors.grey.shade200,
            ),
            errorWidget: (context, url, error) => Container(
              height: 160,
              width: double.infinity,
              color: Colors.grey.shade200,
              alignment: Alignment.center,
              child: const Icon(Icons.home, size: 48, color: Colors.grey),
            ),
          );
    return SizedBox(height: 160, width: double.infinity, child: image);
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('$label: ', style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _RebateTile extends StatelessWidget {
  final String title;
  final String amount;
  const _RebateTile({required this.title, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            amount,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
