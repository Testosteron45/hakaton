import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/venue.dart';
import '../models/swipe_session.dart';

/// Swipe analytics for a venue — shown on the owner's stats screen.
class VenueStats {
  const VenueStats({
    required this.name,
    required this.impressions,
    required this.likes,
    required this.dislikes,
    required this.modeStats,
  });

  final String name;
  final int impressions;
  final int likes;
  final int dislikes;
  // mode.name → {likes, dislikes}
  final Map<String, Map<String, int>> modeStats;

  double get likeRate =>
      impressions == 0 ? 0 : (likes / impressions).clamp(0.0, 1.0);

  factory VenueStats.fromMap(String name, Map<String, dynamic> d) {
    final stats = d['stats'] as Map? ?? {};
    final rawMode = d['modeStats'] as Map? ?? {};
    final modeStats = rawMode.map((k, v) {
      final m = v as Map? ?? {};
      return MapEntry(
        k as String,
        {
          'likes': (m['likes'] as num?)?.toInt() ?? 0,
          'dislikes': (m['dislikes'] as num?)?.toInt() ?? 0,
        },
      );
    });
    return VenueStats(
      name: name,
      impressions: (stats['impressions'] as num?)?.toInt() ?? 0,
      likes: (stats['likes'] as num?)?.toInt() ?? 0,
      dislikes: (stats['dislikes'] as num?)?.toInt() ?? 0,
      modeStats: modeStats,
    );
  }
}

/// Result of a single swipe — used for venue analytics.
class VenueSwipeRecord {
  const VenueSwipeRecord({
    required this.venueId,
    required this.liked,
    required this.mode,
  });
  final String venueId;
  final bool liked;
  final SessionMode mode;
}

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
        _cache = List.unmodifiable(
          snap.docs
              .where((doc) {
                final d = doc.data() as Map<String, dynamic>;
                return d['name'] != null && d['description'] != null;
              })
              .map(Venue.fromFirestore)
              .toList(),
        );
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

  /// Adds a user-created venue to Firestore and updates the local cache.
  /// Returns the Firestore auto-generated ID.
  Future<String> addVenue(Venue venue, {required String ownerUid}) async {
    final now = DateTime.now();
    final data = {
      ...venue.toFirestore(),
      'createdBy': ownerUid,
      'createdAt': Timestamp.fromDate(now),
    };
    final ref = await _firestore.collection('venues').add(data);
    final saved = Venue(
      id: ref.id,
      name: venue.name,
      description: venue.description,
      photoUrl: venue.photoUrl,
      type: venue.type,
      distance: venue.distance,
      group: venue.group,
      price: venue.price,
      features: venue.features,
      address: venue.address,
      category: venue.category,
      tags: venue.tags,
      lat: venue.lat,
      lon: venue.lon,
      mapUrl: venue.mapUrl,
      rating: venue.rating,
      createdAt: now,
    );
    _cache = List.unmodifiable([..._cache, saved]);
    return ref.id;
  }

  /// Deletes a venue from Firestore and removes it from the local cache.
  Future<void> deleteVenue(String venueId) async {
    await _firestore.collection('venues').doc(venueId).delete();
    _cache = List.unmodifiable(_cache.where((v) => v.id != venueId));
  }

  /// Loads stats for a specific venue (swipe analytics written by SwipeSessionNotifier).
  Future<VenueStats?> loadVenueStats(String venueId) async {
    try {
      final doc = await _firestore.collection('venues').doc(venueId).get();
      if (!doc.exists) return null;
      final d = doc.data()! as Map<String, dynamic>;
      return VenueStats.fromMap(d['name'] as String? ?? '', d);
    } catch (_) {
      return null;
    }
  }

  /// Batch-writes swipe stats to each venue document in Firestore.
  /// Tracks: total likes, dislikes, impressions, and per-session-mode breakdown.
  /// Called once after a session completes (not per-swipe) to minimise writes.
  Future<void> updateVenueStats(List<VenueSwipeRecord> records) async {
    if (records.isEmpty) return;
    final batch = _firestore.batch();
    final venuesCol = _firestore.collection('venues');

    for (final r in records) {
      final ref = venuesCol.doc(r.venueId);
      final modeName = r.mode.name;
      batch.set(
        ref,
        {
          'stats': {
            'impressions': FieldValue.increment(1),
            if (r.liked) 'likes': FieldValue.increment(1),
            if (!r.liked) 'dislikes': FieldValue.increment(1),
          },
          'modeStats': {
            modeName: {
              if (r.liked) 'likes': FieldValue.increment(1),
              if (!r.liked) 'dislikes': FieldValue.increment(1),
            },
          },
        },
        SetOptions(merge: true),
      );
    }

    try {
      await batch.commit();
    } catch (e) {
      _log.e('Failed to update venue stats: $e');
    }
  }
}
