import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/venue.dart';
import '../models/swipe_session.dart';

class VenueRepository {
  VenueRepository(this._firestore);

  final FirebaseFirestore _firestore;
  final _log = Logger();

  List<Venue> _cache = const [];

  /// Fetches venues from Firestore and caches them.
  Future<void> loadFromFirestore() async {
    try {
      final snap = await _firestore.collection('venues').get();
      if (snap.docs.isNotEmpty) {
        _cache = List.unmodifiable(snap.docs.map(Venue.fromFirestore).toList());
        _log.i('Loaded ${_cache.length} venues from Firestore.');
      }
    } catch (e) {
      _log.e('Firestore load failed: $e');
    }
  }


  List<Venue> getAll() => _cache;

  Venue? getById(String id) {
    try {
      return _cache.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Build session queue of [count] cards for the given [mode].
  /// Cards are selected to maximally cover different dimensions
  /// (distance, group, price, type, features) so the algorithm
  /// has enough signal after the session.
  List<Venue> buildSessionQueue(SessionMode mode, {int count = 12}) {
    final rng = Random();

    // 1. Filter by mode constraints
    var pool = _cache.toList();

    final requiredFeatures = mode.requiredFeatures;
    if (requiredFeatures != null && mode != SessionMode.normal) {
      pool = pool
          .where((v) => v.features.any((f) => requiredFeatures.contains(f)))
          .toList();
    }

    final reqPrice = mode.requiredPrice;
    if (reqPrice != null) {
      pool = pool.where((v) => v.price == reqPrice).toList();
    }

    // Category filter takes priority over legacy requiredType
    final reqCats = mode.requiredCategories;
    if (reqCats != null) {
      pool = pool.where((v) => reqCats.contains(v.category)).toList();
    } else {
      final reqType = mode.requiredType;
      if (reqType != null) {
        pool = pool
            .where((v) =>
                v.type == VenueType.restaurant || v.type == VenueType.cafe)
            .toList();
      }
    }

    if (pool.length <= count) {
      pool.shuffle(rng);
      return pool;
    }

    // 2. Stratified sampling: ensure coverage of distance/group/price
    final selected = <Venue>[];
    final buckets = <List<Venue>>[];

    for (final dist in DistanceTag.values) {
      for (final grp in GroupTag.values) {
        final bucket = pool
            .where((v) => v.distance == dist && v.group == grp)
            .toList()
          ..shuffle(rng);
        if (bucket.isNotEmpty) buckets.add(bucket);
      }
    }

    buckets.shuffle(rng);
    final usedIds = <String>{};

    for (final bucket in buckets) {
      for (final v in bucket) {
        if (!usedIds.contains(v.id)) {
          selected.add(v);
          usedIds.add(v.id);
          if (selected.length >= count) break;
        }
      }
      if (selected.length >= count) break;
    }

    // 3. Fill up with random if needed
    if (selected.length < count) {
      final remaining = pool.where((v) => !usedIds.contains(v.id)).toList()
        ..shuffle(rng);
      for (final v in remaining) {
        selected.add(v);
        if (selected.length >= count) break;
      }
    }

    selected.shuffle(rng);
    return selected.take(count).toList();
  }
}
