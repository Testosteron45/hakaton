import 'package:cloud_firestore/cloud_firestore.dart';

enum VenueType {
  restaurant,
  cafe,
  park,
  museum,
  temple,
  bar,
  spa,
  sport,
  attraction,
  embankment,
  mall,
  theater,
}

enum DistanceTag {
  near,   // <3 km от центра
  medium, // 3–15 km
  far,    // >15 km
}

enum GroupTag {
  solo,
  couple,
  friends,
  family,
  largeGroup,
}

enum PriceTag {
  budget,
  mid,
  premium,
}

enum VenueFeature {
  kids,
  christian,
  sport,
  romantic,
  outdoor,
  alcohol,
  vegetarian,
  quiet,
  lively,
  cultural,
  historical,
  nature,
}

class Venue {
  const Venue({
    required this.id,
    required this.name,
    required this.description,
    required this.photoUrl,
    required this.type,
    required this.distance,
    required this.group,
    required this.price,
    required this.features,
    required this.address,
    this.category = '',
    this.tags = const [],
    this.lat,
    this.lon,
    this.mapUrl,
    this.rating,
    this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final String photoUrl;
  final VenueType type;
  final DistanceTag distance;
  final GroupTag group;
  final PriceTag price;
  final List<VenueFeature> features;
  final String address;
  // Broad category for session filtering (e.g. "музей", "парк", "винодельня")
  final String category;
  // Russian-language tags for fine-grained recommendation scoring
  final List<String> tags;
  final double? lat;
  final double? lon;
  // Yandex Maps link for navigation
  final String? mapUrl;
  // Yandex Maps rating (1.0–5.0)
  final double? rating;
  final DateTime? createdAt;

  factory Venue.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Venue(
      id: doc.id,
      name: d['name'] as String,
      description: d['description'] as String,
      photoUrl: d['photoUrl'] as String? ?? '',
      type: VenueType.values.firstWhere(
        (e) => e.name == d['type'],
        orElse: () => VenueType.attraction,
      ),
      distance: DistanceTag.values.firstWhere(
        (e) => e.name == d['distance'],
        orElse: () => DistanceTag.near,
      ),
      group: GroupTag.values.firstWhere(
        (e) => e.name == d['group'],
        orElse: () => GroupTag.solo,
      ),
      price: PriceTag.values.firstWhere(
        (e) => e.name == d['price'],
        orElse: () => PriceTag.mid,
      ),
      features: (d['features'] as List<dynamic>? ?? [])
          .map((f) => VenueFeature.values.firstWhere(
                (e) => e.name == f,
                orElse: () => VenueFeature.cultural,
              ))
          .toList(),
      address: d['address'] as String? ?? '',
      category: d['category'] as String? ?? '',
      tags: List<String>.from(d['tags'] as List<dynamic>? ?? []),
      lat: (d['lat'] as num?)?.toDouble(),
      lon: (d['lon'] as num?)?.toDouble(),
      mapUrl: d['mapUrl'] as String?,
      rating: (d['rating'] as num?)?.toDouble(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'description': description,
        'photoUrl': photoUrl,
        'type': type.name,
        'distance': distance.name,
        'group': group.name,
        'price': price.name,
        'features': features.map((f) => f.name).toList(),
        'address': address,
        'category': category,
        'tags': tags,
        if (lat != null) 'lat': lat,
        if (lon != null) 'lon': lon,
        if (mapUrl != null) 'mapUrl': mapUrl,
        if (rating != null) 'rating': rating,
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      };
}
