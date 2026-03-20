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
}
