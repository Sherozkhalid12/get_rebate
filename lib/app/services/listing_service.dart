import 'dart:async';
import 'package:uuid/uuid.dart';

import '../models/listing.dart';

abstract class ListingService {
  Future<List<Listing>> listListings({String? zip, String? city});
  Future<Listing?> getListing(String id);
  Future<List<Listing>> listAgentListings(String agentId);
  Future<Listing> createListing(Listing listing);
  Future<Listing> updateListing(Listing listing);
  Future<void> deleteListing(String id);
  Future<void> incrementStats(
    String id, {
    bool search = false,
    bool view = false,
    bool contact = false,
  });
}

class InMemoryListingService implements ListingService {
  final Map<String, Listing> _store = <String, Listing>{};
  final Uuid _uuid = const Uuid();

  @override
  Future<List<Listing>> listListings({String? zip, String? city}) async {
    Iterable<Listing> values = _store.values;
    if (zip != null && zip.isNotEmpty) {
      values = values.where((l) => l.address.zip == zip);
    }
    if (city != null && city.isNotEmpty) {
      values = values.where(
        (l) => l.address.city.toLowerCase() == city.toLowerCase(),
      );
    }
    return values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Listing?> getListing(String id) async {
    return _store[id];
  }

  @override
  Future<List<Listing>> listAgentListings(String agentId) async {
    return _store.values.where((l) => l.agentId == agentId).toList();
  }

  @override
  Future<Listing> createListing(Listing listing) async {
    final String id = listing.id.isEmpty ? _uuid.v4() : listing.id;
    final Listing toSave = listing.copyWith(id: id, createdAt: DateTime.now());
    _store[id] = toSave;
    return toSave;
  }

  @override
  Future<Listing> updateListing(Listing listing) async {
    if (listing.id.isEmpty || !_store.containsKey(listing.id)) {
      throw StateError('Listing not found');
    }
    _store[listing.id] = listing;
    return listing;
  }

  @override
  Future<void> deleteListing(String id) async {
    _store.remove(id);
  }

  @override
  Future<void> incrementStats(
    String id, {
    bool search = false,
    bool view = false,
    bool contact = false,
  }) async {
    final Listing? listing = _store[id];
    if (listing == null) return;
    final ListingStats oldStats = listing.stats;
    final ListingStats newStats = oldStats.copyWith(
      searches: search ? oldStats.searches + 1 : oldStats.searches,
      views: view ? oldStats.views + 1 : oldStats.views,
      contacts: contact ? oldStats.contacts + 1 : oldStats.contacts,
    );
    _store[id] = listing.copyWith(stats: newStats);
  }
}
